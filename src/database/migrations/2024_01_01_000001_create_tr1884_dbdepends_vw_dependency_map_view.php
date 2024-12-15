<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        if (DB::connection()->getDriverName() !== 'pgsql') {
            return;
        }

        $viewSql = file_get_contents(__DIR__ . '/sql/create_dependency_map_view.sql');
        DB::statement($viewSql);
    }

    public function down()
    {
        if (DB::connection()->getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('DROP VIEW IF EXISTS public.tr1884_dbdepends_vw_dependency_map');
    }
};