<div class="p-4">
    @if($requests->count() > 0)
        <h4 class="text-lg font-semibold mb-2">Pending Follow Requests</h4>
        <ul class="space-y-2">
            @foreach($requests as $user)
                <li class="flex justify-between items-center bg-gray-100/50 dark:bg-gray-800/50 p-2 rounded">
                    <div class="flex items-center gap-2">
                        @if ($user->profile_image)
                                <flux:avatar
                                    circle
                                    {{-- src="{{ asset('storage/' . $org->profile_image) }}" --}}
                                    src="{{ Storage::disk('digitalocean')->url($user->profile_image) }}"
                                    class="size-8 overflow-hidden"
                                    
                                />
                            @else
                                <flux:avatar
                                    circle
                                    :initials="$user->initials()"
                                    class="size-16 lg:size-24 text-lg lg:text-2xl "
                                />
                            @endif
                            <span>{{ $user->name }}</span>
                    </div>
                    <div class="flex gap-2">
                        <flux:button size="sm" color="green" wire:click="accept({{ $user->id }})">Accept</flux:button>
                        <flux:button size="sm" color="red" wire:click="reject({{ $user->id }})">Reject</flux:button>
                    </div>
                </li>
            @endforeach
        </ul>
    @else
        <p class="text-sm text-gray-500">No pending requests</p>
    @endif
</div>
