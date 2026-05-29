<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        $user = User::with('roles', 'department')->where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $plainToken = Str::random(80);

        ApiToken::create([
            'user_id' => $user->id,
            'name' => 'flutter-mobile',
            'token' => hash('sha256', $plainToken),
            'expires_at' => now()->addDays(30),
        ]);

        return response()->json([
            'message' => 'Login success',
            'token' => $plainToken,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'department_id' => $user->department_id,
                'department_name' => $user->department?->name,
                'roles' => $user->roles->pluck('name')->values(),
            ],
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->load('department', 'roles'));
    }

    public function logout(Request $request)
    {
        $token = $request->bearerToken();

        if ($token) {
            ApiToken::where('token', hash('sha256', $token))->delete();
        }

        return response()->json(['message' => 'Logged out']);
    }
}
