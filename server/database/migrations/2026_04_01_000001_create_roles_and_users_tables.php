<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('users');
        Schema::dropIfExists('roles');
        Schema::enableForeignKeyConstraints();

        Schema::create('roles', function (Blueprint $table) {
            $table->string('id', 191)->primary();
            $table->string('name', 191)->unique();
            $table->dateTime('createdAt')->useCurrent();
        });

        $departmentTable = null;
        if (Schema::hasTable('departments')) {
            $departmentTable = 'departments';
        } elseif (Schema::hasTable('Department')) {
            $departmentTable = 'Department';
        }

        $departmentColumn = null;
        if ($departmentTable !== null) {
            $departmentColumn = DB::selectOne(
                "SELECT CHARACTER_MAXIMUM_LENGTH AS max_length,
                        CHARACTER_SET_NAME AS charset_name,
                        COLLATION_NAME AS collation_name
                 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = ?
                   AND COLUMN_NAME = 'id'",
                [$departmentTable]
            );
        }

        Schema::create('users', function (Blueprint $table) use ($departmentColumn) {
            $table->string('id', 191)->primary();

            $table->string('employeeCode', 191)->unique()->nullable();
            $table->string('name', 191)->nullable();
            $table->string('email', 191)->unique()->nullable();
            $table->string('contactNumber', 191)->unique();
            $table->string('alternativeNumber', 191)->nullable();

            $table->string('roleId', 191)->nullable();
            $table->json('roles')->nullable();

            $departmentIdLength = 10;
            if ($departmentColumn !== null && $departmentColumn->max_length !== null) {
                $departmentIdLength = (int) $departmentColumn->max_length;
            }

            $departmentIdColumn = $table->string('departmentId', $departmentIdLength)->nullable();
            if ($departmentColumn !== null && $departmentColumn->charset_name) {
                $departmentIdColumn->charset($departmentColumn->charset_name);
            }
            if ($departmentColumn !== null && $departmentColumn->collation_name) {
                $departmentIdColumn->collation($departmentColumn->collation_name);
            }

            $table->string('otp', 191)->nullable();
            $table->dateTime('otpExpiry')->nullable();
            $table->dateTime('lastLogin')->nullable();

            $table->boolean('isActive')->default(true);

            $table->dateTime('createdAt')->useCurrent();
            $table->dateTime('updatedAt')->useCurrent()->useCurrentOnUpdate();

            $table->dateTime('dateOfBirth')->nullable();
            $table->string('gender', 50)->nullable();
            $table->text('image')->nullable();

            $table->json('preferredLanguages')->nullable();

            $table->text('address')->nullable();
            $table->string('city', 191)->nullable();
            $table->string('state', 191)->nullable();
            $table->string('pincode', 20)->nullable();
            $table->string('country', 191)->nullable();
            $table->string('district', 191)->nullable();
            $table->string('area', 191)->nullable();

            $table->double('latitude')->nullable();
            $table->double('longitude')->nullable();

            $table->string('aadharCard', 191)->nullable();
            $table->string('panCard', 191)->nullable();
            $table->string('password', 255)->nullable();
            $table->text('notes')->nullable();

            $table->string('workStartTime', 8)->default('09:00:00');
            $table->string('workEndTime', 8)->default('18:00:00');
            $table->integer('latePunchInGraceMinutes')->default(45);
            $table->integer('earlyPunchOutGraceMinutes')->default(30);
        });

        Schema::table('users', function (Blueprint $table) use ($departmentTable) {
            $table->foreign('roleId')->references('id')->on('roles')->nullOnDelete();
        });

        if ($departmentTable !== null) {
            $usersDepartment = DB::selectOne(
                "SELECT CHARACTER_MAXIMUM_LENGTH AS max_length,
                        CHARACTER_SET_NAME AS charset_name,
                        COLLATION_NAME AS collation_name
                 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = 'users'
                   AND COLUMN_NAME = 'departmentId'"
            );
            $departmentId = DB::selectOne(
                "SELECT CHARACTER_MAXIMUM_LENGTH AS max_length,
                        CHARACTER_SET_NAME AS charset_name,
                        COLLATION_NAME AS collation_name
                 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = ?
                   AND COLUMN_NAME = 'id'",
                [$departmentTable]
            );

            $compatibleDepartmentFk = $usersDepartment !== null && $departmentId !== null
                && (int) $usersDepartment->max_length === (int) $departmentId->max_length
                && (string) $usersDepartment->charset_name === (string) $departmentId->charset_name
                && (string) $usersDepartment->collation_name === (string) $departmentId->collation_name;

            if ($compatibleDepartmentFk) {
                Schema::table('users', function (Blueprint $table) use ($departmentTable) {
                    $table->foreign('departmentId')->references('id')->on($departmentTable)->nullOnDelete();
                });
            }
        }

        DB::table('roles')->insert([
            ['id' => 'R001', 'name' => 'Admin'],
            ['id' => 'R002', 'name' => 'Employee'],
            ['id' => 'R003', 'name' => 'Manager'],
            ['id' => 'R004', 'name' => 'Telecaller'],
            ['id' => 'R005', 'name' => 'Developer'],
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('users');
        Schema::dropIfExists('roles');
        Schema::enableForeignKeyConstraints();
    }
};
