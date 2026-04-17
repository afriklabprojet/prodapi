@php
    $documentPath = $getState();
@endphp

<div class="p-2">
    @if ($documentPath)
        @php
            $url = route('admin.documents.view', ['path' => $documentPath]);
        @endphp
        <a href="{{ $url }}" target="_blank" class="block hover:opacity-80 transition-opacity">
            <img src="{{ $url }}" alt="Document KYC"
                class="max-h-48 rounded-lg border-2 border-gray-200 shadow-sm hover:border-primary-500 transition-colors"
                onerror="this.parentElement.innerHTML='<div class=\'p-4 bg-red-50 text-red-600 rounded-lg border border-red-200\'>❌ Erreur de chargement</div>'" />
        </a>
    @else
        <div class="p-4 bg-gray-50 text-gray-500 rounded-lg border border-gray-200 flex items-center justify-center">
            <span class="text-sm">📄 Non fourni</span>
        </div>
    @endif
</div>
