<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TrustProxies
{
    /**
     * Les proxies de confiance (load balancers, reverse proxies).
     * '*' = faire confiance à tous les proxies (adapté pour Docker/Kubernetes).
     */
    protected array $proxies = ['*'];

    /**
     * Les en-têtes à utiliser pour détecter le proxy.
     */
    protected int $headers = Request::HEADER_X_FORWARDED_FOR |
                              Request::HEADER_X_FORWARDED_HOST |
                              Request::HEADER_X_FORWARDED_PORT |
                              Request::HEADER_X_FORWARDED_PROTO |
                              Request::HEADER_X_FORWARDED_AWS_ELB;

    public function handle(Request $request, Closure $next): Response
    {
        $request->setTrustedProxies(
            $this->proxies,
            $this->headers
        );

        return $next($request);
    }
}
