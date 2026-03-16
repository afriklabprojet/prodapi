@php
    $idFront = $getRecord()->id_card_front_document;
    $selfie = $getRecord()->selfie_document;
    $idBack = $getRecord()->id_card_back_document;
@endphp

<div class="flex gap-1 items-center">
    @if ($idFront)
        <a href="{{ route('admin.documents.view', ['path' => $idFront]) }}" target="_blank" title="CNI Recto">
            <img src="{{ route('admin.documents.view', ['path' => $idFront]) }}"
                class="w-10 h-10 object-cover rounded border border-gray-200 hover:border-blue-500 transition-colors"
                onerror="this.style.display='none'" />
        </a>
    @endif

    @if ($selfie)
        <a href="{{ route('admin.documents.view', ['path' => $selfie]) }}" target="_blank" title="Selfie">
            <img src="{{ route('admin.documents.view', ['path' => $selfie]) }}"
                class="w-10 h-10 object-cover rounded border-2 border-amber-400 hover:border-amber-600 transition-colors"
                onerror="this.style.display='none'" />
        </a>
    @endif

    @if ($idBack)
        <a href="{{ route('admin.documents.view', ['path' => $idBack]) }}" target="_blank" title="CNI Verso">
            <img src="{{ route('admin.documents.view', ['path' => $idBack]) }}"
                class="w-10 h-10 object-cover rounded border border-gray-200 hover:border-blue-500 transition-colors"
                onerror="this.style.display='none'" />
        </a>
    @endif

    @if (!$idFront && !$selfie && !$idBack)
        <span class="text-xs text-gray-400">Aucun document</span>
    @endif
</div>
