# load_raw.py: nạp dữ liệu thô vào Postgres.
import sys
import pandas as pd
from sqlalchemy import text
from config import RAW_SHEET, RAW_XLSX, get_engine

TARGET_SCHEMA = "raw"
TARGET_TABLE = "transactions"
COLUMN_MAP = {
    "TransactionID": "transaction_id",
    "CustomerID": "customer_id",
    "TransactionDate": "transaction_date",
    "TransactionType": "transaction_type",
    "Amount": "amount",
    "ProductCategory": "product_category",
    "ProductSubcategory": "product_subcategory",
    "BranchCity": "branch_city",
    "BranchLat": "branch_lat",
    "BranchLong": "branch_long",
    "Channel": "channel",
    "Currency": "currency",
    "CreditCardFees": "credit_card_fees",
    "InsuranceFees": "insurance_fees",
    "LatePaymentAmount": "late_payment_amount",
    "CustomerScore": "customer_score",
    "MonthlyIncome": "monthly_income",
    "CustomerSegment": "customer_segment",
    "RecommendedOffer": "recommended_offer",}
def read_source() -> pd.DataFrame:
   
    if not RAW_XLSX.exists():
        sys.exit(f"[LỖI] Không tìm thấy file: {RAW_XLSX}")
    df = pd.read_excel(RAW_XLSX, sheet_name=RAW_SHEET)
    print(f"Đã đọc  : {RAW_XLSX.name} / sheet '{RAW_SHEET}'")
    print(f"Kích thước: {df.shape[0]:,} dòng x {df.shape[1]} cột")

    # Cảnh báo nếu file nguồn khác với COLUMN_MAP
    missing = set(COLUMN_MAP) - set(df.columns)
    extra = set(df.columns) - set(COLUMN_MAP)
    if missing:
        sys.exit(f"[LỖI] File nguồn thiếu cột: {sorted(missing)}")
    if extra:
        print(f"[CẢNH BÁO] Cột chưa có trong COLUMN_MAP, sẽ giữ nguyên tên: {sorted(extra)}")
    return df.rename(columns=COLUMN_MAP)

def load_to_postgres(df: pd.DataFrame) -> None:
    """Ghi đè bảng raw.transactions bằng dữ liệu trong df."""
    engine = get_engine()
    with engine.begin() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {TARGET_SCHEMA}"))

    # if_exists="replace" 
    df.to_sql(
        TARGET_TABLE,
        engine,
        schema=TARGET_SCHEMA, if_exists="replace", index=False, chunksize=5_000, method="multi",)
    print(f"Đã ghi  : {TARGET_SCHEMA}.{TARGET_TABLE}")

    # Đối chiếu số dòng 
    with engine.connect() as conn:
        n_db = conn.execute(
            text(f"SELECT COUNT(*) FROM {TARGET_SCHEMA}.{TARGET_TABLE}")
        ).scalar_one()
    print(f"\nĐối chiếu số dòng")
    print(f"  Excel   : {len(df):,}")
    print(f"  Postgres: {n_db:,}")
    if n_db != len(df):
        sys.exit("[LỖI] Số dòng không khớp — dừng lại để kiểm tra.")
    print("  => Khớp. Nạp dữ liệu thành công.")

def main() -> None:
    df = read_source()
    load_to_postgres(df)
if __name__ == "__main__":
    main()