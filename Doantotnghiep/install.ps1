$ErrorActionPreference = "Stop"

Write-Host ">>> API INSTALLER V20: FINAL SEEDER FIX <<<" -ForegroundColor Cyan

# 1. Project Setup
if ((Test-Path "D:\api-tutor") -and -not (Test-Path "D:\api-tutor\artisan")) {
    Write-Host "Found empty/broken D:\api-tutor. Deleting..." -ForegroundColor Yellow
    Remove-Item "D:\api-tutor" -Recurse -Force
}

if (-not (Test-Path "D:\api-tutor")) {
    Write-Host "Creating Laravel Project (Fresh)..." -ForegroundColor Yellow
    cd D:\
    composer create-project laravel/laravel api-tutor
} else {
    Write-Host "Updating existing Project..." -ForegroundColor Yellow
}

cd D:\api-tutor

# 2. FORCE API Registration
Write-Host "Registering API Routes..." -ForegroundColor Cyan
if (-not (Test-Path "routes/api.php")) {
    Set-Content "routes/api.php" "<?php"
}
try {
    php artisan install:api --no-interaction 2>&1 | Out-Null
} catch {
    Write-Host "API config skipped." -ForegroundColor Gray
}

# 3. Ensure Directories Exist
Write-Host "Ensuring Directories..." -ForegroundColor Green
New-Item -ItemType Directory -Path "app\Models" -Force | Out-Null
New-Item -ItemType Directory -Path "app\Http\Controllers\Api" -Force | Out-Null
New-Item -ItemType Directory -Path "database\migrations" -Force | Out-Null
New-Item -ItemType Directory -Path "database\seeders" -Force | Out-Null

# 4. Clean Old Migrations
Write-Host "Cleaning Default Migrations..." -ForegroundColor Green
Remove-Item "database\migrations\*.php" -Force -ErrorAction SilentlyContinue

# 5. Copy Files (Now includes SharedLearningController)
Write-Host "Copying Code..." -ForegroundColor Green
$source = "C:\Users\Dung\AndroidStudioProjects\Doantotnghiep\laravel_setup"

Copy-Item -Path "$source\app\Models\*" -Destination "app\Models" -Force
Copy-Item -Path "$source\app\Http\Controllers\Api\*" -Destination "app\Http\Controllers\Api" -Force
Copy-Item -Path "$source\routes\api.php" -Destination "routes\api.php" -Force
Copy-Item -Path "$source\database\migrations\*" -Destination "database\migrations" -Force
Copy-Item -Path "$source\database\seeders\*" -Destination "database\seeders" -Force

# 6. RESTORE DEFAULT MIGRATIONS
Write-Host "Restoring Sessions & Sanctum Migrations..." -ForegroundColor Cyan
php artisan session:table
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider" --tag="sanctum-migrations" --force

# 7. Setup Env
Write-Host "Configuring Environment..." -ForegroundColor Green
if (-not (Test-Path ".env")) { 
    Copy-Item ".env.example" ".env" 
}
php artisan key:generate
php artisan storage:link

# Fix 1071 key length error
if (Test-Path "app\Providers\AppServiceProvider.php") {
    $providerContent = Get-Content "app\Providers\AppServiceProvider.php" -Raw
    if (-not ($providerContent -like "*Schema::defaultStringLength(191)*")) {
        $providerContent = $providerContent -replace "use Illuminate\\\\Support\\\\ServiceProvider;", "use Illuminate\Support\ServiceProvider;`nuse Illuminate\Support\Facades\Schema;"
        $providerContent = $providerContent -replace "public function boot\(\).*?\{", "public function boot()`n    {`n        Schema::defaultStringLength(191);"
        Set-Content "app\Providers\AppServiceProvider.php" -Value $providerContent
    }
}

# 8. Install Dependencies
Write-Host "Checking Sanctum..." -ForegroundColor Green
composer require laravel/sanctum

# 9. Migrate
Write-Host "Migrating Database..." -ForegroundColor Magenta
php artisan migrate:fresh --seed

Write-Host ">>> INSTALLATION SUCCESSFUL! <<<" -ForegroundColor Cyan
Write-Host "Shared Learning API Deployed." -ForegroundColor White
Write-Host "Run: php artisan serve --host 0.0.0.0" -ForegroundColor White
