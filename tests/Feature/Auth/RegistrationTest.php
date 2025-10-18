<?php

use Livewire\Volt\Volt;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;





test('registration screen can be rendered', function () {
    $response = $this->get('/register');

    $response->assertStatus(200);
});

test('new users can register', function () {
    Storage::fake('public');
    $photo = UploadedFile::fake()->image('avatar.jpg');
    $response = Volt::test('auth.register')
        ->set('name', 'Test User')
        ->set('email', 'test@example.com')
        ->set('password', 'password')
        ->set('password_confirmation', 'password')
        ->set('photo', $photo)
        ->call('register');

    $response
        ->assertHasNoErrors()
        ->assertRedirect(route(url('/'), absolute: false));

    $this->assertAuthenticated();
});