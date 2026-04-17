<div class="p-3">
    {{-- Info client --}}
    <div class="bg-gray-100 p-3 rounded-lg mb-4">
        <p><strong>Client:</strong> {{ $customer?->name ?? 'Inconnu' }}</p>
        <p><strong>Téléphone:</strong> {{ $customer?->phone ?? 'N/A' }}</p>
        <p><strong>Email:</strong> {{ $customer?->email ?? 'N/A' }}</p>
        @if($prescription->notes)
            <p><strong>Notes:</strong> {{ $prescription->notes }}</p>
        @endif
    </div>

    {{-- Images ordonnance --}}
    @if(empty($images))
        <p class="text-center text-gray-500">Aucune image</p>
    @else
        <div class="flex flex-col gap-4 items-center">
            @foreach($images as $image)
                @php $url = route('admin.documents.view', ['path' => $image]); @endphp
                <div class="text-center">
                    <a href="{{ $url }}" target="_blank" title="Cliquer pour ouvrir dans un nouvel onglet">
                        <img src="{{ $url }}" class="max-w-full max-h-[500px] rounded-lg shadow-md" alt="Ordonnance" />
                    </a>
                </div>
            @endforeach
        </div>
    @endif
</div>
