<div class="p-4">
    {{-- Info livreur --}}
    <div class="bg-gradient-to-br from-blue-500 to-blue-700 text-white p-4 rounded-xl mb-5">
        <h3 class="text-lg font-bold mb-2">📋 Informations du livreur</h3>
        <p class="my-1"><strong>Nom:</strong> {{ $courier->name }}</p>
        <p class="my-1"><strong>Téléphone:</strong> {{ $courier->phone ?? 'N/A' }}</p>
        <p class="my-1"><strong>Email:</strong> {{ $courier->user?->email ?? 'N/A' }}</p>
        <p class="my-1">
            <strong>Véhicule:</strong>
            @switch($courier->vehicle_type)
                @case('motorcycle') 🏍️ Moto - {{ $courier->vehicle_number ?? '' }} @break
                @case('car') 🚗 Voiture - {{ $courier->vehicle_number ?? '' }} @break
                @case('bicycle') 🚲 Vélo @break
                @default {{ $courier->vehicle_type }}
            @endswitch
        </p>
        @if($courier->license_number)
            <p class="my-1"><strong>N° Permis:</strong> {{ $courier->license_number }}</p>
        @endif
    </div>

    {{-- CNI Recto/Verso --}}
    <div class="mb-6">
        <h4 class="text-gray-700 font-semibold mb-3 flex items-center gap-2">🪪 Carte d'Identité Nationale (CNI)</h4>
        <div class="grid grid-cols-2 gap-4">
            {{-- Recto --}}
            <div class="text-center">
                <div class="bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-3">
                    <p class="font-semibold text-gray-500 text-sm mb-2">RECTO</p>
                    @if($courier->id_card_front_document)
                        @php $url = route('admin.documents.view', ['path' => $courier->id_card_front_document]); @endphp
                        <a href="{{ $url }}" target="_blank">
                            <img src="{{ $url }}" class="max-w-full max-h-[250px] rounded-lg shadow-sm mx-auto" alt="CNI Recto" />
                        </a>
                    @else
                        <div class="h-[150px] flex items-center justify-center text-red-600">❌ Non fourni</div>
                    @endif
                </div>
            </div>
            {{-- Verso --}}
            <div class="text-center">
                <div class="bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-3">
                    <p class="font-semibold text-gray-500 text-sm mb-2">VERSO</p>
                    @if($courier->id_card_back_document)
                        @php $url = route('admin.documents.view', ['path' => $courier->id_card_back_document]); @endphp
                        <a href="{{ $url }}" target="_blank">
                            <img src="{{ $url }}" class="max-w-full max-h-[250px] rounded-lg shadow-sm mx-auto" alt="CNI Verso" />
                        </a>
                    @else
                        <div class="h-[150px] flex items-center justify-center text-red-600">❌ Non fourni</div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    {{-- Selfie --}}
    <div class="mb-6">
        <h4 class="text-gray-700 font-semibold mb-3 flex items-center gap-2">📸 Selfie de Vérification</h4>
        <div class="text-center bg-amber-50 border-2 border-amber-400 rounded-xl p-4">
            @if($courier->selfie_document)
                @php $url = route('admin.documents.view', ['path' => $courier->selfie_document]); @endphp
                <a href="{{ $url }}" target="_blank">
                    <img src="{{ $url }}" class="max-w-[300px] max-h-[300px] rounded-xl shadow-md mx-auto" alt="Selfie" />
                </a>
                <p class="mt-2 text-amber-800 text-sm">💡 Comparer avec la photo sur la CNI</p>
            @else
                <div class="h-[150px] flex items-center justify-center text-red-600 text-base">❌ Selfie non fourni</div>
            @endif
        </div>
    </div>

    {{-- Permis de conduire --}}
    @if($courier->driving_license_front_document || $courier->driving_license_back_document)
        <div class="mb-6">
            <h4 class="text-gray-700 font-semibold mb-3 flex items-center gap-2">🚗 Permis de Conduire</h4>
            <div class="grid grid-cols-2 gap-4">
                {{-- Recto --}}
                <div class="text-center">
                    <div class="bg-green-50 border-2 border-dashed border-green-300 rounded-xl p-3">
                        <p class="font-semibold text-gray-500 text-sm mb-2">RECTO</p>
                        @if($courier->driving_license_front_document)
                            @php $url = route('admin.documents.view', ['path' => $courier->driving_license_front_document]); @endphp
                            <a href="{{ $url }}" target="_blank">
                                <img src="{{ $url }}" class="max-w-full max-h-[220px] rounded-lg mx-auto" alt="Permis Recto" />
                            </a>
                        @else
                            <div class="h-[120px] flex items-center justify-center text-gray-400">Non fourni</div>
                        @endif
                    </div>
                </div>
                {{-- Verso --}}
                <div class="text-center">
                    <div class="bg-green-50 border-2 border-dashed border-green-300 rounded-xl p-3">
                        <p class="font-semibold text-gray-500 text-sm mb-2">VERSO</p>
                        @if($courier->driving_license_back_document)
                            @php $url = route('admin.documents.view', ['path' => $courier->driving_license_back_document]); @endphp
                            <a href="{{ $url }}" target="_blank">
                                <img src="{{ $url }}" class="max-w-full max-h-[220px] rounded-lg mx-auto" alt="Permis Verso" />
                            </a>
                        @else
                            <div class="h-[120px] flex items-center justify-center text-gray-400">Non fourni</div>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    @endif

    {{-- Carte grise --}}
    @if($courier->vehicle_registration_document)
        <div class="mb-4">
            <h4 class="text-gray-700 font-semibold mb-3">📄 Carte Grise</h4>
            <div class="text-center">
                @php $url = route('admin.documents.view', ['path' => $courier->vehicle_registration_document]); @endphp
                <a href="{{ $url }}" target="_blank">
                    <img src="{{ $url }}" class="max-w-[350px] max-h-[250px] rounded-lg shadow-sm mx-auto" alt="Carte Grise" />
                </a>
            </div>
        </div>
    @endif
</div>
