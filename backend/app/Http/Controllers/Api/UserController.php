<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ActivityLogger;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        return response()->json(User::with(['department', 'roles', 'superiorUser'])->latest()->get());
    }

    public function show(int $id)
    {
        return response()->json(User::with(['department', 'roles', 'superiorUser'])->findOrFail($id));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'department_id' => ['nullable', 'exists:departments,id'],
            'roles' => ['nullable', 'array'],
            'roles.*' => ['exists:roles,id'],
            'npk' => ['nullable'],
            'job_title' => ['nullable', 'string', 'max:255'],
            'superior' => ['nullable', 'exists:users,id'],
        ]);

        $user = User::create([
            ...collect($validated)->except(['roles'])->toArray(),
            'password' => Hash::make($validated['password']),
        ]);

        $user->roles()->sync($validated['roles'] ?? []);
        ActivityLogger::log('CREATE', 'users', $user->id, null, $user->toArray(), auth()->user()?->name." created user [{$user->id}]");

        return response()->json(['message' => 'User created successfully', 'user' => $user->load('department', 'roles')], 201);
    }

    public function update(Request $request, int $id)
    {
        $user = User::findOrFail($id);
        $oldData = $user->toArray();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'unique:users,email,'.$id],
            'password' => ['nullable', 'string', 'min:6'],
            'department_id' => ['nullable', 'exists:departments,id'],
            'roles' => ['nullable', 'array'],
            'roles.*' => ['exists:roles,id'],
            'npk' => ['nullable'],
            'job_title' => ['nullable', 'string', 'max:255'],
            'superior' => ['nullable', 'exists:users,id'],
        ]);

        $data = collect($validated)->except(['roles', 'password'])->toArray();
        if (! empty($validated['password'])) {
            $data['password'] = Hash::make($validated['password']);
        }

        $user->update($data);

        if (array_key_exists('roles', $validated)) {
            $user->roles()->sync($validated['roles'] ?? []);
        }

        ActivityLogger::log('UPDATE', 'users', $user->id, $oldData, $user->toArray(), auth()->user()?->name." updated user [{$user->id}]");

        return response()->json(['message' => 'User updated successfully', 'data' => $user->load('department', 'roles')]);
    }

    public function destroy(int $id)
    {
        $user = User::findOrFail($id);
        $oldData = $user->toArray();
        $user->roles()->detach();
        $user->delete();

        ActivityLogger::log('DELETE', 'users', $id, $oldData, null, auth()->user()?->name." deleted user [{$id}]");

        return response()->json(['message' => 'User deleted successfully']);
    }

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'oldPassword' => ['nullable'],
            'current_password' => ['nullable'],
            'newPassword' => ['nullable', 'min:6'],
            'new_password' => ['nullable', 'min:6'],
        ]);

        $user = $request->user();
        $oldPassword = $validated['oldPassword'] ?? $validated['current_password'] ?? null;
        $newPassword = $validated['newPassword'] ?? $validated['new_password'] ?? null;

        if (! $oldPassword || ! $newPassword) {
            return response()->json(['error' => 'Password fields are required'], 422);
        }

        if (! Hash::check($oldPassword, $user->password)) {
            return response()->json(['error' => 'Old password is incorrect'], 400);
        }

        $user->forceFill(['password' => Hash::make($newPassword)])->save();

        return response()->json(['message' => 'Password successfully updated']);
    }
}
