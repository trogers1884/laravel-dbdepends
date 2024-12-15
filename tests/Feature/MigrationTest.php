<?php

namespace Trogers1884\DBDepends\Tests\Feature;

use Illuminate\Support\Facades\DB;
use Trogers1884\DBDepends\Tests\TestCase;

class MigrationTest extends TestCase
{
    public function test_view_is_created_when_using_postgresql()
    {
        // Check if the view exists
        $viewExists = DB::select(
            "SELECT EXISTS (
                SELECT FROM pg_views 
                WHERE schemaname = 'public' 
                AND viewname = 'tr1884_dbdepends_vw_dependency_map'
            )"
        );

        $this->assertTrue((bool) $viewExists[0]->exists);
    }

    public function test_view_returns_expected_columns()
    {
        $columns = DB::select("
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'tr1884_dbdepends_vw_dependency_map'
            ORDER BY ordinal_position
        ");

        $expectedColumns = [
            'relation' => 'text',
            'object_type' => 'text',
            'owner' => 'name',
            'deps' => 'bigint',
            'add_deps' => 'integer',
            'reqs' => 'bigint',
            'add_reqs' => 'integer',
            'dependents' => 'text',
            'add_dependents' => 'text',
            'requirements' => 'text',
            'add_requirements' => 'text'
        ];

        foreach ($columns as $column) {
            $this->assertArrayHasKey($column->column_name, $expectedColumns);
            $this->assertTrue(
                str_contains($column->data_type, $expectedColumns[$column->column_name]),
                "Column {$column->column_name} has unexpected data type {$column->data_type}"
            );
        }
    }
}