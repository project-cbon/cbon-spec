# Class-Based Object Notation (CBON) Specification

**Class-Based Object Notation (CBON)** は、厳密な型定義、継承、および高度なバリデーション機能を備えた、データ記述およびスキーマ定義のための言語仕様です。

JSONやYAMLの柔軟性に、静的型付け言語のような型安全性とドメイン特化なデータ型（mail, datetime等）を組み合わせています。

---

## 1. 主な特徴

* **強力な型システム**: プリミティブ型に加え、Union型 (`A | B`) やジェネリクス (`array<T>`) をサポート。
* **クラスベースの構造**: 継承 (`extends`) により、共通フィールドを効率的に管理。
* **高度な制約**: 正規表現 (`regexp`)、数値・時間の範囲制限 (`range`)、特定値の許可 (`accept`) が可能。
* **フィールド制御**: フィールド間の排他制御 (`exclusive`) や、いずれか1つを必須とする (`oneof`) 定義をサポート。
* **ネイティブデータ型**: `mail`, `datetime`, `date`, `time` など、現代的なアプリケーションで頻用される型を標準提供。

---

## 2. 命名規約

識別子のケース（大文字・小文字）によって、その役割を明確に区別します。

| 種類 | 書式 | 例 | 備考 |
| :--- | :--- | :--- | :--- |
| **カスタム型** | **PascalCase** | `User`, `OrderCode` | `class`, `enum`, `regexp`, `range`, `accept` で定義。 |
| **ビルトイン型** | **lowercase** | `string`, `int`, `mail` | 言語が標準で提供するプリミティブ型。 |
| **フィールド名** | **snake_case** | `created_at`, `is_active` | `class` 定義内のプロパティ名。 |

---

## 3. スキーマ定義 (Definitions)

### クラス (`class`)
構造化データを定義します。
* **修飾子**: `required` (必須), `optional` (任意), `choose` (選択式)。
* **初期化**: `const` (定数固定), `default` (デフォルト値)。
* **グループ制約**: `oneof` (1つのみ必須), `exclusive` (排他)。

### 範囲制限 (`range`)
数値、日付、時刻の有効範囲を定義します。
* `[` `]` (境界を含む) と `(` `)` (境界を含まない) を使用。 `inf` で無限を指定。

### その他
* **`enum`**: 名前付き定数のリスト。
* **`regexp`**: 正規表現による文字列パターンの強制。
* **`accept`**: 許可するリテラル値のホワイトリスト。

---

## 4. データ記述 (Values)

CBONのデータは、常に型名を伴うオブジェクト形式、またはプリミティブなスカラー値として記述されます。

### オブジェクトと配列
```
// オブジェクト
User {
    id: 1,
    name: "Taro Yamada"
}

// 配列
array<int> { 1, 1, 2, 3, 5 }
```

### スカラー型
* **文字列**: `"text"`
* **数値**: `123`, `-45.67`
* **真偽値**: `true`, `false`
* **特殊型**: `user@example.com`, `2026-01-30 10:00:00`, `09:00`

---

## 5. スキーマ定義例

`example.cbon`

```
/** 商品コードの形式を定義 */
regexp ProductCode /^[A-Z]{3}-[0-9]{5}$/;

/** 自然数の定義（範囲制約） */
range Natural<int> { [1, inf) }

/** 営業時間の定義（時間の範囲制約） */
range OpenHours<time> { [09:00, 12:00), [13:00, 18:00) }

/** 配送ステータスの定義 */
enum DeliveryStatus {
    Pending,
    InTransit,
    Delivered,
    Returned
}

/** 基底クラス */
class BaseEntity {
    required string type;
    required Natural<int> id;
    optional datetime created_at;
}

/** ユーザー情報 */
class User extends BaseEntity {
    required string name;
    required mail email;
    const type "User";
}

/** 注文アイテム */
class OrderItem {
    required ProductCode code;
    required Natural<int> quantity;
    required int|decimal unit_price; 
}

/** 配送情報 */
class Delivery {
    required DeliveryStatus status;
    choose boolean is_drop_off;
    choose string signature_name;
    
    exclusive is_drop_off, signature_name;
}

/** メインの注文スキーマ */
class Order extends BaseEntity {
    required User customer;
    required array<OrderItem> items;
    required Delivery logistics;
    const type "Order";
}

/* スキーマのルート宣言 */
schema Order;
```
