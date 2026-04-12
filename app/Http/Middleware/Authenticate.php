<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    /**
     * Retourner null pour les requêtes API afin d'éviter
     * l'erreur "Route [login] not defined".
     */
    protected function redirectTo(Request $request): ?string
    {
        if ($request->is('api/*') || $request->expectsJson()) {
            return null;
        }

        return '/finance/login';
    }
}
