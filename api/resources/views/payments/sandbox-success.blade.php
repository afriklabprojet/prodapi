<!DOCTYPE html>
<html>
<head><title>Sandbox Payment Success</title></head>
<body>
    <h1>{{ $message }}</h1>
    <p>Reference: {{ $payment->reference ?? ($payment['reference'] ?? 'N/A') }}</p>
</body>
</html>
