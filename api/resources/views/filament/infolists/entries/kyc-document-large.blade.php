@php
    $documentPath = $getState();
@endphp

<div class="p-4 flex justify-center">
    @if ($documentPath)
        @php
            $url = route('admin.documents.view', ['path' => $documentPath]);
        @endphp
        <div class="bg-amber-50 border-2 border-amber-400 rounded-xl p-4 shadow-lg">
            <a href="{{ $url }}" target="_blank" class="block hover:opacity-80 transition-opacity">
                <img src="{{ $url }}" alt="Selfie de vérification" class="max-h-72 rounded-lg"
                    onerror="this.parentElement.innerHTML='<div class=\'p-4 bg-red-50 text-red-600 rounded-lg\'>❌ Erreur de chargement</div>'" />
            </a>
            <p class="text-center text-amber-700 text-sm mt-3 font-medium">
                💡 Comparer ce selfie avec la photo sur la CNI
            </p>
        </div>
    @else
        <div
            class="p-6 bg-red-50 text-red-600 rounded-xl border-2 border-red-200 flex flex-col items-center justify-center">
            <span class="text-4xl mb-2">❌</span>
            <span class="font-medium">Selfie non fourni</span>
            <span class="text-sm text-red-500">Ce document est obligatoire</span>
        </div>
    @endif
</div>
