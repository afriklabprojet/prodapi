<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\ResourceCollection;

class MessageCollection extends ResourceCollection
{
    /**
     * L'utilisateur courant pour déterminer is_mine
     */
    private ?array $currentUser = null;

    /**
     * Définir l'utilisateur courant pour tous les messages
     */
    public function setCurrentUser(array $currentUser): self
    {
        $this->currentUser = $currentUser;
        return $this;
    }

    /**
     * Transform the resource collection into an array.
     */
    public function toArray(Request $request): array
    {
        return $this->collection->map(function ($message) {
            $resource = new MessageResource($message);
            if ($this->currentUser) {
                $resource->setCurrentUser($this->currentUser);
            }
            return $resource;
        })->all();
    }

    /**
     * Additional data to include in the response.
     */
    public function with(Request $request): array
    {
        return [
            'success' => true,
        ];
    }
}
