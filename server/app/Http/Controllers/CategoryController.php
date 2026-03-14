<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Category::query();

            if ($request->has('parent_cat_id')) {
                $query->where('parent_cat_id', (int) $request->input('parent_cat_id'));
            }

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%');
                    if (is_numeric($search)) {
                        $q->orWhere('cat_id', (int) $search);
                    }
                });
            }

            if ($request->has('only_active')) {
                $query->where('is_active', filter_var($request->input('only_active'), FILTER_VALIDATE_BOOLEAN));
            }

            $sortField = $request->input('sort', 'name');
            $sortOrder = $request->input('order', 'asc');
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }
            $query->orderBy($sortField, $sortOrder);

            $limit = (int) $request->input('limit', 50);
            $page = (int) $request->input('page', 1);
            $total = $query->count();
            $categories = $query->skip(($page - 1) * $limit)->take($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $categories,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => $limit > 0 ? (int) ceil($total / $limit) : 0,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Category index error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch categories',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $category = Category::with(['parent', 'children'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $category,
            ]);
        } catch (\Exception $e) {
            Log::error('Category show error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Category not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:250',
            'parent_cat_id' => [
                'required',
                'integer',
                'min:0',
                Rule::when($request->input('parent_cat_id') > 0, ['exists:categories,cat_id']),
            ],
            'is_active' => 'nullable|boolean',
            'type' => 'nullable|integer|min:0|max:255',
            'image_slug' => 'nullable|string|max:15',
            'image_name' => 'nullable|string',
        ]);

        $validated['parent_cat_id'] = (int) $validated['parent_cat_id'];
        $validated['is_active'] = $validated['is_active'] ?? true;
        $validated['type'] = $validated['type'] ?? 0;
        $validated['image_slug'] = $validated['image_slug'] ?? ' ';
        $validated['img_last_updated'] = $validated['img_last_updated'] ?? 0;

        try {
            $category = Category::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Category created successfully',
                'data' => $category,
            ], 201);
        } catch (\Exception $e) {
            Log::error('Category store error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to create category',
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:250',
            'parent_cat_id' => [
                'sometimes',
                'required',
                'integer',
                'min:0',
                Rule::when($request->input('parent_cat_id') > 0, ['exists:categories,cat_id']),
            ],
            'is_active' => 'nullable|boolean',
            'type' => 'nullable|integer|min:0|max:255',
            'image_slug' => 'nullable|string|max:15',
            'image_name' => 'nullable|string',
        ]);

        if (array_key_exists('parent_cat_id', $validated)) {
            $parentCatId = (int) $validated['parent_cat_id'];
            if ($parentCatId === $id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Category cannot be its own parent',
                ], 422);
            }
        }

        try {
            $category = Category::findOrFail($id);
            $category->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Category updated successfully',
                'data' => $category->fresh(),
            ]);
        } catch (\Exception $e) {
            Log::error('Category update error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to update category',
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $category = Category::findOrFail($id);

            if ($category->children()->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete category that has subcategories. Remove or reassign subcategories first.',
                ], 422);
            }

            if (Product::where('cat_id', $id)->exists()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete category that is assigned to products. Reassign products first.',
                ], 422);
            }

            $category->delete();

            return response()->json([
                'success' => true,
                'message' => 'Category deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Category destroy error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete category',
            ], 500);
        }
    }
}
