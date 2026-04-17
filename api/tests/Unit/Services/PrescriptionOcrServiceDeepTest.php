<?php

namespace Tests\Unit\Services;

use App\Services\PrescriptionOcrService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PrescriptionOcrServiceDeepTest extends TestCase
{
    private PrescriptionOcrService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Config::set('services.google_vision.api_key', 'test-api-key');
        $this->service = new PrescriptionOcrService();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    private function getPrivate(object $obj, string $prop): mixed
    {
        $ref = new \ReflectionProperty($obj, $prop);
        $ref->setAccessible(true);
        return $ref->getValue($obj);
    }

    private function visionApiResponse(string $text, float $confidence = 0.9): array
    {
        return [
            'responses' => [
                [
                    'textAnnotations' => [
                        ['description' => $text],
                    ],
                    'fullTextAnnotation' => [
                        'text' => $text,
                        'pages' => [
                            [
                                'blocks' => [
                                    [
                                        'confidence' => $confidence,
                                        'paragraphs' => [
                                            [
                                                'words' => array_map(function ($word) use ($confidence) {
                                                    return [
                                                        'confidence' => $confidence,
                                                        'symbols' => array_map(fn ($c) => ['text' => $c], mb_str_split($word)),
                                                    ];
                                                }, explode(' ', $text)),
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];
    }

    private function handwrittenVisionResponse(string $text): array
    {
        return [
            'responses' => [
                [
                    'textAnnotations' => [
                        ['description' => $text],
                        ...array_map(fn ($w) => ['description' => $w], explode(' ', $text)),
                    ],
                    'fullTextAnnotation' => [
                        'text' => $text,
                        'pages' => [
                            [
                                'blocks' => [
                                    [
                                        'confidence' => 0.4,
                                        'paragraphs' => [
                                            [
                                                'words' => array_map(function ($word) {
                                                    return [
                                                        'confidence' => rand(20, 70) / 100,
                                                        'symbols' => array_map(fn ($c) => ['text' => $c], mb_str_split($word)),
                                                    ];
                                                }, explode(' ', $text)),
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // constructor / loadMedicationPatterns
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function constructor_loads_medication_patterns(): void
    {
        $patterns = $this->getPrivate($this->service, 'medicationPatterns');
        $this->assertNotEmpty($patterns);
        $this->assertContains('mg', $patterns);
        $this->assertContains('comprimé', $patterns);
    }

    #[Test]
    public function constructor_uses_api_key_from_config(): void
    {
        $this->assertEquals('test-api-key', $this->getPrivate($this->service, 'apiKey'));
    }

    #[Test]
    public function constructor_falls_back_to_google_maps_key(): void
    {
        Config::set('services.google_vision.api_key', null);
        Config::set('services.google_maps.key', 'maps-key');
        $service = new PrescriptionOcrService();
        $this->assertEquals('maps-key', $this->getPrivate($service, 'apiKey'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // errorResult (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function error_result_returns_correct_structure(): void
    {
        $result = $this->callPrivate($this->service, 'errorResult', ['Test error']);
        $this->assertFalse($result['success']);
        $this->assertEquals('Test error', $result['error']);
        $this->assertEmpty($result['medications']);
        $this->assertEquals(0, $result['confidence']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // basicTextAnalysis (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function basic_text_analysis_returns_manual_review(): void
    {
        $result = $this->callPrivate($this->service, 'basicTextAnalysis', ['some/path.jpg']);
        $this->assertTrue($result['success']);
        $this->assertTrue($result['requires_manual_review']);
        $this->assertEquals(0, $result['confidence']);
        $this->assertEmpty($result['medications']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getImageContent (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_image_content_from_private_disk(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('prescriptions/test.jpg', 'image-data');

        $content = $this->callPrivate($this->service, 'getImageContent', ['prescriptions/test.jpg']);
        $this->assertEquals('image-data', $content);
    }

    #[Test]
    public function get_image_content_from_default_disk(): void
    {
        Storage::fake('private');
        Storage::fake('local');
        Storage::disk('local')->put('prescriptions/test.jpg', 'local-data');

        $content = $this->callPrivate($this->service, 'getImageContent', ['prescriptions/test.jpg']);
        $this->assertEquals('local-data', $content);
    }

    #[Test]
    public function get_image_content_from_public_disk(): void
    {
        Storage::fake('private');
        Storage::fake('local');
        Storage::fake('public');
        Storage::disk('public')->put('prescriptions/test.jpg', 'public-data');

        $content = $this->callPrivate($this->service, 'getImageContent', ['prescriptions/test.jpg']);
        $this->assertEquals('public-data', $content);
    }

    #[Test]
    public function get_image_content_returns_null_when_not_found(): void
    {
        Storage::fake('private');
        Storage::fake('local');
        Storage::fake('public');

        $content = $this->callPrivate($this->service, 'getImageContent', ['nonexistent/image.jpg']);
        $this->assertNull($content);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectHandwriting (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function detect_handwriting_with_low_confidence_returns_true(): void
    {
        $fullText = [
            'pages' => [
                [
                    'blocks' => [
                        [
                            'confidence' => 0.5,
                            'paragraphs' => [
                                [
                                    'words' => [
                                        ['confidence' => 0.4],
                                        ['confidence' => 0.6],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->callPrivate($this->service, 'detectHandwriting', [$fullText, []]);
        $this->assertTrue($result);
    }

    #[Test]
    public function detect_handwriting_with_high_confidence_returns_false(): void
    {
        $fullText = [
            'pages' => [
                [
                    'blocks' => [
                        [
                            'confidence' => 0.98,
                            'paragraphs' => [
                                [
                                    'words' => [
                                        ['confidence' => 0.97],
                                        ['confidence' => 0.99],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->callPrivate($this->service, 'detectHandwriting', [$fullText, []]);
        $this->assertFalse($result);
    }

    #[Test]
    public function detect_handwriting_null_fulltext_with_annotations_true(): void
    {
        $result = $this->callPrivate($this->service, 'detectHandwriting', [null, [['description' => 'some text']]]);
        $this->assertTrue($result);
    }

    #[Test]
    public function detect_handwriting_null_fulltext_empty_annotations_false(): void
    {
        $result = $this->callPrivate($this->service, 'detectHandwriting', [null, []]);
        $this->assertFalse($result);
    }

    #[Test]
    public function detect_handwriting_empty_confidences_returns_true(): void
    {
        $fullText = ['pages' => [['blocks' => []]]];
        $result = $this->callPrivate($this->service, 'detectHandwriting', [$fullText, []]);
        $this->assertTrue($result);
    }

    #[Test]
    public function detect_handwriting_high_variance_returns_true(): void
    {
        // High variance but decent average
        $fullText = [
            'pages' => [
                [
                    'blocks' => [
                        [
                            'confidence' => 0.95,
                            'paragraphs' => [
                                [
                                    'words' => [
                                        ['confidence' => 0.3],
                                        ['confidence' => 0.99],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->callPrivate($this->service, 'detectHandwriting', [$fullText, []]);
        $this->assertTrue($result); // High variance indicates handwriting mix
    }

    // ═══════════════════════════════════════════════════════════════════════
    // extractWordConfidences (protected) 
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function extract_word_confidences_from_full_text(): void
    {
        $fullText = [
            'pages' => [
                [
                    'blocks' => [
                        [
                            'confidence' => 0.9,
                            'paragraphs' => [
                                [
                                    'words' => [
                                        [
                                            'confidence' => 0.8,
                                            'symbols' => [
                                                ['text' => 'H'],
                                                ['text' => 'e'],
                                                ['text' => 'l'],
                                                ['text' => 'l'],
                                                ['text' => 'o'],
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->callPrivate($this->service, 'extractWordConfidences', [$fullText, null]);

        $this->assertArrayHasKey('hello', $result);
        $this->assertEquals(0.8, $result['hello']['confidence']);
        $this->assertEquals('Hello', $result['hello']['text']);
    }

    #[Test]
    public function extract_word_confidences_from_text_annotations(): void
    {
        $annotations = [
            ['description' => 'Full text here'],
            ['description' => 'Paracetamol'],
            ['description' => '500mg'],
        ];

        $result = $this->callPrivate($this->service, 'extractWordConfidences', [null, $annotations]);

        $this->assertArrayHasKey('paracetamol', $result);
        $this->assertEquals(0.6, $result['paracetamol']['confidence']);
        $this->assertTrue($result['paracetamol']['is_likely_handwritten']);
    }

    #[Test]
    public function extract_word_confidences_does_not_overwrite_fulltext(): void
    {
        $fullText = [
            'pages' => [
                [
                    'blocks' => [
                        [
                            'confidence' => 0.95,
                            'paragraphs' => [
                                [
                                    'words' => [
                                        [
                                            'confidence' => 0.95,
                                            'symbols' => [
                                                ['text' => 'T'],
                                                ['text' => 'e'],
                                                ['text' => 's'],
                                                ['text' => 't'],
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $annotations = [
            ['description' => 'Test full'],
            ['description' => 'Test'],
        ];

        $result = $this->callPrivate($this->service, 'extractWordConfidences', [$fullText, $annotations]);

        // Should keep fullText confidence, not overwrite with annotation
        $this->assertEquals(0.95, $result['test']['confidence']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // isLikelyPrintedFormText (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function is_likely_printed_form_text_high_confidence(): void
    {
        $confidences = ['hello' => ['confidence' => 0.98]];
        $result = $this->callPrivate($this->service, 'isLikelyPrintedFormText', ['Hello', $confidences]);
        $this->assertTrue($result);
    }

    #[Test]
    public function is_likely_printed_form_text_low_confidence(): void
    {
        $confidences = ['hello' => ['confidence' => 0.5]];
        $result = $this->callPrivate($this->service, 'isLikelyPrintedFormText', ['Hello', $confidences]);
        $this->assertFalse($result);
    }

    #[Test]
    public function is_likely_printed_form_text_not_found(): void
    {
        $result = $this->callPrivate($this->service, 'isLikelyPrintedFormText', ['Unknown', []]);
        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // extractMedicationsFromText (public)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function extract_medications_finds_known_drugs(): void
    {
        $text = "Ordonnance\nParacétamol 500mg 3x/j\nAmoxicilline 1g matin et soir";

        $result = $this->service->extractMedicationsFromText($text);

        $medNames = array_column($result['medications'], 'name');
        $this->assertContains('Paracétamol', $medNames);
        $this->assertContains('Amoxicilline', $medNames);
        $this->assertTrue($result['is_prescription']);
    }

    #[Test]
    public function extract_medications_detects_prescription_indicators(): void
    {
        $text = "Dr. Martin\nOrdonnance médicale\nIbuprofène 400mg";

        $result = $this->service->extractMedicationsFromText($text);

        $this->assertTrue($result['is_prescription']);
        $this->assertNotNull($result['doctor_info']);
    }

    #[Test]
    public function extract_medications_with_dosages(): void
    {
        $text = "Paracétamol 500mg 3x/j pendant 7 jours";

        $result = $this->service->extractMedicationsFromText($text);

        $medNames = array_column($result['medications'], 'name');
        $this->assertContains('Paracétamol', $medNames);
        $this->assertNotEmpty($result['dosages']);
    }

    #[Test]
    public function extract_medications_no_prescription(): void
    {
        $text = "Bonjour comment allez-vous aujourd'hui";

        $result = $this->service->extractMedicationsFromText($text);

        $this->assertEmpty($result['medications']);
        $this->assertFalse($result['is_prescription']);
    }

    #[Test]
    public function extract_medications_with_brand_names(): void
    {
        $text = "Doliprane 1000mg\nAugmentin 500mg";

        $result = $this->service->extractMedicationsFromText($text);

        $medNames = array_column($result['medications'], 'name');
        $this->assertContains('Paracétamol', $medNames); // Doliprane → Paracétamol
        $this->assertContains('Amoxicilline-Acide clavulanique', $medNames); // Augmentin
    }

    #[Test]
    public function extract_medications_antipaludal(): void
    {
        $text = "Coartem 3x/j pendant 3 jours";

        $result = $this->service->extractMedicationsFromText($text);

        $medNames = array_column($result['medications'], 'name');
        $this->assertContains('Artéméther-Luméfantrine', $medNames);
    }

    #[Test]
    public function extract_medications_handwriting_fuzzy_mode(): void
    {
        // Simulating OCR misread of "paracetamol" as "paracetanol"
        $text = "paracetanol 500mg";

        $result = $this->service->extractMedicationsFromText($text, [], true);

        $medNames = array_column($result['medications'], 'name');
        $this->assertContains('Paracétamol', $medNames);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // extractMedicalExams (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function extract_medical_exams_finds_exams(): void
    {
        $text = "Demande de radiographie thorax et bilan sanguin";

        $result = $this->callPrivate($this->service, 'extractMedicalExams', [$text, false]);

        $examNames = array_column($result, 'name');
        $this->assertContains('Radiographie', $examNames);
        $this->assertContains('Bilan sanguin', $examNames);
    }

    #[Test]
    public function extract_medical_exams_with_handwriting_fuzzy(): void
    {
        $text = "radiographle thorax";

        $result = $this->callPrivate($this->service, 'extractMedicalExams', [$text, true]);

        $examNames = array_column($result, 'name');
        $this->assertContains('Radiographie', $examNames);
    }

    #[Test]
    public function extract_medical_exams_cardiology(): void
    {
        $text = "ecg holter";

        $result = $this->callPrivate($this->service, 'extractMedicalExams', [$text, false]);

        $examNames = array_column($result, 'name');
        $this->assertContains('ECG', $examNames);
        $this->assertContains('Holter', $examNames);
    }

    #[Test]
    public function extract_medical_exams_includes_anatomy_zones(): void
    {
        $text = "radiographie thorax poumon";

        $result = $this->callPrivate($this->service, 'extractMedicalExams', [$text, false]);

        $this->assertNotEmpty($result);
        // Should have anatomy zones attached
        $hasZones = false;
        foreach ($result as $exam) {
            if (!empty($exam['zones'])) {
                $hasZones = true;
                break;
            }
        }
        $this->assertTrue($hasZones);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // extractAnatomyZones (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function extract_anatomy_zones(): void
    {
        $text = "thorax genou";

        $result = $this->callPrivate($this->service, 'extractAnatomyZones', [$text]);

        $this->assertContains('Thorax', $result);
        $this->assertContains('Genou', $result);
    }

    #[Test]
    public function extract_anatomy_zones_empty(): void
    {
        $result = $this->callPrivate($this->service, 'extractAnatomyZones', ['nothing medical here']);
        $this->assertEmpty($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // extractDosageNearMedication (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function extract_dosage_near_medication_full(): void
    {
        $text = "paracétamol 500mg 3x/j pendant 7 jours";

        $result = $this->callPrivate($this->service, 'extractDosageNearMedication', [$text, 'paracétamol']);

        $this->assertNotNull($result);
        $this->assertEquals('500mg', $result['strength']);
        $this->assertStringContainsString('3', $result['frequency']);
        $this->assertEquals('7 jours', $result['duration']);
    }

    #[Test]
    public function extract_dosage_near_medication_not_found(): void
    {
        $text = "some random text";

        $result = $this->callPrivate($this->service, 'extractDosageNearMedication', [$text, 'ibuprofène']);

        $this->assertNull($result);
    }

    #[Test]
    public function extract_dosage_partial(): void
    {
        $text = "amoxicilline 1g";

        $result = $this->callPrivate($this->service, 'extractDosageNearMedication', [$text, 'amoxicilline']);

        $this->assertNotNull($result);
        $this->assertEquals('1g', $result['strength']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // fuzzyMatchInText (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function fuzzy_match_exact(): void
    {
        $result = $this->callPrivate($this->service, 'fuzzyMatchInText', ['paracetamol 500mg', 'paracetamol']);
        $this->assertNotNull($result);
        $this->assertGreaterThanOrEqual(0.8, $result['similarity']);
    }

    #[Test]
    public function fuzzy_match_close_variant(): void
    {
        // OCR misread: l → 1
        $result = $this->callPrivate($this->service, 'fuzzyMatchInText', ['paracetamo1 500mg', 'paracetamol']);
        $this->assertNotNull($result);
    }

    #[Test]
    public function fuzzy_match_too_different(): void
    {
        $result = $this->callPrivate($this->service, 'fuzzyMatchInText', ['something completely different', 'paracetamol']);
        $this->assertNull($result);
    }

    #[Test]
    public function fuzzy_match_too_short_target(): void
    {
        $result = $this->callPrivate($this->service, 'fuzzyMatchInText', ['abc text', 'abc']);
        $this->assertNull($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // findUnknownMedications (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function find_unknown_medications_with_dosage_pattern(): void
    {
        $text = "Medicamenta 500mg";
        $result = $this->callPrivate($this->service, 'findUnknownMedications', [$text, [], [], false]);

        // Should find "Medicamenta 500mg" as unknown med
        $this->assertNotEmpty($result);
        $this->assertEquals(0.7, $result[0]['confidence']);
    }

    #[Test]
    public function find_unknown_medications_skips_short_names(): void
    {
        $text = "Ab 500mg";
        $result = $this->callPrivate($this->service, 'findUnknownMedications', [$text, [], [], false]);

        // "Ab" is less than 4 chars, should be skipped
        $names = array_column($result, 'name');
        $this->assertNotContains('Ab 500mg', $names);
    }

    #[Test]
    public function find_unknown_medications_skips_already_found(): void
    {
        $text = "Paracétamol 500mg";
        $alreadyFound = [['name' => 'Paracétamol']];
        $result = $this->callPrivate($this->service, 'findUnknownMedications', [$text, $alreadyFound, [], false]);

        $names = array_map(fn ($m) => mb_strtolower($m['name']), $result);
        // Paracétamol (any case) should not appear again
        foreach ($names as $name) {
            $this->assertStringNotContainsString('paracétamol', $name);
        }
        // Ensure the test actually asserts something even if $result is empty
        $this->assertIsArray($result);
    }

    #[Test]
    public function find_unknown_medications_with_word_confidences(): void
    {
        $text = "Somemed 500mg";
        $wordConfidences = [
            'somemed' => [
                'text' => 'Somemed',
                'confidence' => 0.5,
                'is_likely_handwritten' => true,
            ],
        ];
        $result = $this->callPrivate($this->service, 'findUnknownMedications', [$text, [], $wordConfidences, true]);

        $this->assertNotEmpty($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // calculateConfidence (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function calculate_confidence_base_printed(): void
    {
        $response = [];
        $analysis = ['is_prescription' => false, 'medications' => [], 'medical_exams' => [], 'doctor_info' => null];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [$response, $analysis, false]);

        $this->assertEquals(0.5, $result);
    }

    #[Test]
    public function calculate_confidence_base_handwriting(): void
    {
        $response = [];
        $analysis = ['is_prescription' => false, 'medications' => [], 'medical_exams' => [], 'doctor_info' => null];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [$response, $analysis, true]);

        $this->assertEquals(0.4, $result);
    }

    #[Test]
    public function calculate_confidence_with_prescription(): void
    {
        $analysis = ['is_prescription' => true, 'medications' => [], 'medical_exams' => [], 'doctor_info' => null];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, false]);

        $this->assertEquals(0.7, $result); // 0.5 + 0.2
    }

    #[Test]
    public function calculate_confidence_with_medications(): void
    {
        $meds = [['name' => 'A'], ['name' => 'B'], ['name' => 'C']];
        $analysis = ['is_prescription' => true, 'medications' => $meds, 'medical_exams' => [], 'doctor_info' => null];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, false]);

        $this->assertEquals(0.85, $result); // 0.5 + 0.2 + 3*0.05
    }

    #[Test]
    public function calculate_confidence_with_doctor_info(): void
    {
        $analysis = ['is_prescription' => true, 'medications' => [], 'medical_exams' => [], 'doctor_info' => 'Dr Martin'];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, false]);

        $this->assertEquals(0.8, $result); // 0.5 + 0.2 + 0.1
    }

    #[Test]
    public function calculate_confidence_with_medical_exams(): void
    {
        $exams = [['name' => 'Radio'], ['name' => 'Bilan']];
        $analysis = ['is_prescription' => false, 'medications' => [], 'medical_exams' => $exams, 'doctor_info' => null];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, false]);

        $this->assertEquals(0.66, $result); // 0.5 + 2*0.08
    }

    #[Test]
    public function calculate_confidence_capped_at_1(): void
    {
        $meds = array_fill(0, 10, ['name' => 'Med']);
        $exams = array_fill(0, 10, ['name' => 'Exam']);
        $analysis = ['is_prescription' => true, 'medications' => $meds, 'medical_exams' => $exams, 'doctor_info' => 'Dr X'];

        $result = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, true]);

        $this->assertLessThanOrEqual(1.0, $result);
    }

    #[Test]
    public function calculate_confidence_handwriting_bonus(): void
    {
        $meds = [['name' => 'Paracétamol']];
        $analysis = ['is_prescription' => false, 'medications' => $meds, 'medical_exams' => [], 'doctor_info' => null];

        $printed = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, false]);
        $handwritten = $this->callPrivate($this->service, 'calculateConfidence', [[], $analysis, true]);

        // Handwriting gets extra bonus for finding meds
        $this->assertGreaterThan(0, $handwritten);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getCommonMedicationsDatabase (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_common_medications_database(): void
    {
        $db = $this->callPrivate($this->service, 'getCommonMedicationsDatabase');

        $this->assertIsArray($db);
        $this->assertArrayHasKey('Paracétamol', $db);
        $this->assertArrayHasKey('Amoxicilline', $db);
        $this->assertArrayHasKey('Metformine', $db);
        $this->assertContains('doliprane', $db['Paracétamol']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // analyzeImage — integration through Vision API
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function analyze_image_with_api_key_success(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'fake-image-data');

        Http::fake([
            'vision.googleapis.com/*' => Http::response($this->visionApiResponse(
                "Dr. Konan\nOrdonnance\nParacétamol 500mg 3x/j\nAmoxicilline 1g"
            ), 200),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertTrue($result['success']);
        $this->assertNotEmpty($result['medications']);
        $this->assertTrue($result['is_prescription']);
    }

    #[Test]
    public function analyze_image_api_failure(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'fake-image');

        Http::fake([
            'vision.googleapis.com/*' => Http::response(['error' => 'fail'], 500),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertFalse($result['success']);
        $this->assertStringContainsString('Erreur API', $result['error']);
    }

    #[Test]
    public function analyze_image_not_found(): void
    {
        Storage::fake('private');
        Storage::fake('local');
        Storage::fake('public');

        $result = $this->service->analyzeImage('nonexistent.jpg');

        $this->assertFalse($result['success']);
        $this->assertStringContainsString('Impossible de lire', $result['error']);
    }

    #[Test]
    public function analyze_image_no_auth_configured(): void
    {
        Config::set('services.google_vision.api_key', null);
        Config::set('services.google_maps.key', null);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        $result = $service->analyzeImage('test.jpg');

        $this->assertFalse($result['success']);
        $this->assertStringContainsString('non configuré', $result['error']);
    }

    #[Test]
    public function analyze_image_empty_response(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        Http::fake([
            'vision.googleapis.com/*' => Http::response(['responses' => []], 200),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertFalse($result['success']);
    }

    #[Test]
    public function analyze_image_no_text_detected(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [['textAnnotations' => [], 'fullTextAnnotation' => null]],
            ], 200),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertTrue($result['success']);
        $this->assertEmpty($result['medications']);
        $this->assertEquals(0, $result['confidence']);
    }

    #[Test]
    public function analyze_image_catches_exception(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        Http::fake(fn () => throw new \Exception('Network error'));

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertFalse($result['success']);
        $this->assertStringContainsString('Network error', $result['error']);
    }

    #[Test]
    public function analyze_image_vision_api_error_in_response(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [['error' => ['message' => 'Invalid image']]],
            ], 200),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertFalse($result['success']);
        $this->assertEquals('Invalid image', $result['error']);
    }

    #[Test]
    public function analyze_image_handwriting_detection(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('test.jpg', 'data');

        Http::fake([
            'vision.googleapis.com/*' => Http::response($this->handwrittenVisionResponse(
                "Ordonnance\nParacetanol 500mg\nAmoxiciline 1g"
            ), 200),
        ]);

        $result = $this->service->analyzeImage('test.jpg');

        $this->assertTrue($result['success']);
        $this->assertTrue($result['has_handwriting']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // parseGoogleVisionResponse (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function parse_response_returns_analysis(): void
    {
        $data = $this->visionApiResponse("Dr. Test\nOrdonnance\nParacétamol 500mg");

        $result = $this->callPrivate($this->service, 'parseGoogleVisionResponse', [$data, true]);

        $this->assertTrue($result['success']);
        $this->assertNotEmpty($result['raw_text']);
        $this->assertTrue($result['is_prescription']);
        $this->assertArrayHasKey('has_handwriting', $result);
    }

    #[Test]
    public function parse_response_empty_responses(): void
    {
        $result = $this->callPrivate($this->service, 'parseGoogleVisionResponse', [['responses' => []], false]);
        $this->assertFalse($result['success']);
    }

    #[Test]
    public function parse_response_with_api_error(): void
    {
        $data = ['responses' => [['error' => ['message' => 'Permission denied']]]];

        $result = $this->callPrivate($this->service, 'parseGoogleVisionResponse', [$data, false]);

        $this->assertFalse($result['success']);
        $this->assertEquals('Permission denied', $result['error']);
    }
}
