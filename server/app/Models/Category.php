<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $table = 'categories';

    protected $primaryKey = 'cat_id';

    public $timestamps = false;

    protected $fillable = [
        'name',
        'parent_cat_id',
        'is_active',
        'type',
        'image_slug',
        'image_name',
        'img_last_updated',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'parent_cat_id' => 'integer',
        'type' => 'integer',
        'img_last_updated' => 'integer',
    ];

    public function parent()
    {
        return $this->belongsTo(Category::class, 'parent_cat_id', 'cat_id');
    }

    public function children()
    {
        return $this->hasMany(Category::class, 'parent_cat_id', 'cat_id');
    }
}
