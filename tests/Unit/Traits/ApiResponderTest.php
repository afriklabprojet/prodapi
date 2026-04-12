<?php

namespace Tests\Unit\Traits;

use App\Traits\ApiResponder;
use Tests\TestCase;

class ApiResponderTest extends TestCase
{
    private object $responder;

    protected function setUp(): void
    {
        parent::setUp();
        $this->responder = new class {
            use ApiResponder;

            public function callSuccess($data = null, string $message = 'Opération réussie', int $code = 200, array $meta = [])
            {
                return $this->success($data, $message, $code, $meta);
            }

            public function callCreated($data = null, string $message = 'Ressource créée avec succès')
            {
                return $this->created($data, $message);
            }

            public function callError(string $message = 'Une erreur est survenue', int $code = 400, ?string $errorCode = null, $errors = null, ?string $details = null, ?array $action = null)
            {
                return $this->error($message, $code, $errorCode, $errors, $details, $action);
            }

            public function callNotFound(string $message = 'Ressource non trouvée', ?string $errorCode = null)
            {
                return $this->notFound($message, $errorCode);
            }

            public function callForbidden(string $message = 'Accès refusé', ?string $errorCode = null)
            {
                return $this->forbidden($message, $errorCode);
            }

            public function callUnauthorized(string $message = 'Non authentifié', ?string $errorCode = null)
            {
                return $this->unauthorized($message, $errorCode);
            }

            public function callConflict(string $message = 'Conflit détecté', ?string $errorCode = null, $data = null)
            {
                return $this->conflict($message, $errorCode, $data);
            }

            public function callValidationError(string $message = 'Données invalides', $errors = null)
            {
                return $this->validationError($message, $errors);
            }

            public function callServerError(string $message = 'Erreur interne du serveur')
            {
                return $this->serverError($message);
            }

            public function callPaymentError(string $message, ?string $errorCode = null, $data = null)
            {
                return $this->paymentError($message, $errorCode, $data);
            }

            public function callPaginated($paginator, $data = null, string $message = 'Liste récupérée')
            {
                return $this->paginated($paginator, $data, $message);
            }
        };
    }

    public function test_success_returns_200_with_correct_structure(): void
    {
        $response = $this->responder->callSuccess(['key' => 'value']);
        $data = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($data['success']);
        $this->assertSame('Opération réussie', $data['message']);
        $this->assertSame(['key' => 'value'], $data['data']);
    }

    public function test_success_without_data(): void
    {
        $response = $this->responder->callSuccess();
        $data = $response->getData(true);

        $this->assertArrayNotHasKey('data', $data);
    }

    public function test_success_with_meta(): void
    {
        $response = $this->responder->callSuccess(['item'], 'OK', 200, ['page' => 1]);
        $data = $response->getData(true);

        $this->assertSame(['page' => 1], $data['meta']);
    }

    public function test_success_without_meta(): void
    {
        $response = $this->responder->callSuccess(['item']);
        $data = $response->getData(true);

        $this->assertArrayNotHasKey('meta', $data);
    }

    public function test_created_returns_201(): void
    {
        $response = $this->responder->callCreated(['id' => 1]);
        $data = $response->getData(true);

        $this->assertSame(201, $response->getStatusCode());
        $this->assertTrue($data['success']);
        $this->assertSame('Ressource créée avec succès', $data['message']);
    }

    public function test_error_returns_correct_structure(): void
    {
        $response = $this->responder->callError('Something failed', 400, 'CUSTOM_ERROR');
        $data = $response->getData(true);

        $this->assertSame(400, $response->getStatusCode());
        $this->assertFalse($data['success']);
        $this->assertSame('Something failed', $data['message']);
        $this->assertSame('CUSTOM_ERROR', $data['error_code']);
    }

    public function test_error_with_details_and_action(): void
    {
        $response = $this->responder->callError('Err', 400, null, null, 'Details here', ['type' => 'retry']);
        $data = $response->getData(true);

        $this->assertSame('Details here', $data['details']);
        $this->assertSame(['type' => 'retry'], $data['action']);
    }

    public function test_error_with_validation_errors(): void
    {
        $errors = ['email' => ['Required']];
        $response = $this->responder->callError('Validation', 422, null, $errors);
        $data = $response->getData(true);

        $this->assertSame($errors, $data['errors']);
    }

    public function test_not_found_returns_404(): void
    {
        $response = $this->responder->callNotFound();
        $data = $response->getData(true);

        $this->assertSame(404, $response->getStatusCode());
        $this->assertSame('NOT_FOUND', $data['error_code']);
    }

    public function test_not_found_with_custom_error_code(): void
    {
        $response = $this->responder->callNotFound('Not here', 'CUSTOM_404');
        $data = $response->getData(true);

        $this->assertSame('CUSTOM_404', $data['error_code']);
    }

    public function test_forbidden_returns_403(): void
    {
        $response = $this->responder->callForbidden();
        $data = $response->getData(true);

        $this->assertSame(403, $response->getStatusCode());
        $this->assertSame('FORBIDDEN', $data['error_code']);
    }

    public function test_unauthorized_returns_401(): void
    {
        $response = $this->responder->callUnauthorized();
        $data = $response->getData(true);

        $this->assertSame(401, $response->getStatusCode());
        $this->assertSame('UNAUTHENTICATED', $data['error_code']);
    }

    public function test_conflict_returns_409(): void
    {
        $response = $this->responder->callConflict('Already exists', 'DUPLICATE', ['id' => 5]);
        $data = $response->getData(true);

        $this->assertSame(409, $response->getStatusCode());
        $this->assertSame('DUPLICATE', $data['error_code']);
        $this->assertSame(['id' => 5], $data['data']);
    }

    public function test_conflict_without_data(): void
    {
        $response = $this->responder->callConflict();
        $data = $response->getData(true);

        $this->assertSame(409, $response->getStatusCode());
        $this->assertArrayNotHasKey('data', $data);
    }

    public function test_validation_error_returns_422(): void
    {
        $errors = ['name' => ['The name field is required.']];
        $response = $this->responder->callValidationError('Données invalides', $errors);
        $data = $response->getData(true);

        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame('VALIDATION_ERROR', $data['error_code']);
        $this->assertSame($errors, $data['errors']);
    }

    public function test_server_error_returns_500(): void
    {
        $response = $this->responder->callServerError();
        $data = $response->getData(true);

        $this->assertSame(500, $response->getStatusCode());
        $this->assertSame('INTERNAL_ERROR', $data['error_code']);
    }

    public function test_payment_error_returns_400_with_retry_action(): void
    {
        $response = $this->responder->callPaymentError('Payment failed');
        $data = $response->getData(true);

        $this->assertSame(400, $response->getStatusCode());
        $this->assertSame('PAYMENT_ERROR', $data['error_code']);
        $this->assertSame('retry', $data['action']['type']);
    }

    public function test_payment_error_with_custom_code_and_data(): void
    {
        $response = $this->responder->callPaymentError('Timeout', 'PAYMENT_TIMEOUT', ['ref' => 'TX123']);
        $data = $response->getData(true);

        $this->assertSame('PAYMENT_TIMEOUT', $data['error_code']);
        $this->assertSame(['ref' => 'TX123'], $data['data']);
    }

    public function test_paginated_response(): void
    {
        $paginator = new \Illuminate\Pagination\LengthAwarePaginator(
            items: [['id' => 1], ['id' => 2]],
            total: 10,
            perPage: 2,
            currentPage: 1,
        );

        $response = $this->responder->callPaginated($paginator);
        $data = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertTrue($data['success']);
        $this->assertSame(1, $data['meta']['current_page']);
        $this->assertSame(5, $data['meta']['last_page']);
        $this->assertSame(2, $data['meta']['per_page']);
        $this->assertSame(10, $data['meta']['total']);
    }

    public function test_paginated_with_custom_data(): void
    {
        $paginator = new \Illuminate\Pagination\LengthAwarePaginator(
            items: [['id' => 1]],
            total: 1,
            perPage: 10,
            currentPage: 1,
        );

        $customData = [['id' => 1, 'transformed' => true]];
        $response = $this->responder->callPaginated($paginator, $customData, 'Custom');
        $data = $response->getData(true);

        $this->assertSame($customData, $data['data']);
        $this->assertSame('Custom', $data['message']);
    }
}
