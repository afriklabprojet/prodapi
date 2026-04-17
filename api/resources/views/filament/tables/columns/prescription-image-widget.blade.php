@php
    $images = $getRecord()->getRawImages();
    $firstImage = $images[0] ?? null;
    $url = $firstImage ? route('admin.documents.view', ['path' => $firstImage]) : null;
@endphp

@if ($url)
    <img src="{{ $url }}" alt="Ordonnance"
        style="width: 80px; height: 100px; object-fit: cover; border-radius: 6px; cursor: pointer;" loading="lazy" />
@else
    <div
        style="width: 80px; height: 100px; background: #f3f4f6; border-radius: 6px; display: flex; align-items: center; justify-content: center;">
        <span style="color: #9ca3af; font-size: 10px;">Aucune image</span>
    </div>
@endif
