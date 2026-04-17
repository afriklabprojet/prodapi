@php
    $images = $getRecord()->getRawImages();
    $firstImage = $images[0] ?? null;
    $url = $firstImage ? route('admin.documents.view', ['path' => $firstImage]) : null;
@endphp

@if ($url)
    <img src="{{ $url }}" alt="Ordonnance"
        style="width: 60px; height: 80px; object-fit: cover; border-radius: 4px;" loading="lazy" />
@else
    <div
        style="width: 60px; height: 80px; background: #f3f4f6; border-radius: 4px; display: flex; align-items: center; justify-content: center;">
        <span style="color: #9ca3af; font-size: 10px;">Aucune</span>
    </div>
@endif
