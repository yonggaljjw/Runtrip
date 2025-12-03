# backend/models/user_model.py

import bcrypt

class UserModel:
    def __init__(self, db):
        self.db = db

    # 이메일로 유저 찾기 (dict로 리턴)
    def get_by_email(self, email: str):
        conn = self.db.get_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(
                """
                SELECT
                    id,
                    email,
                    nickname,
                    password_hash,
                    running_level,   
                    city             
                FROM users
                WHERE email = %s
                """,
                (email,)
            )
            row = cursor.fetchone()
            return row  # 없으면 None
        finally:
            cursor.close()
            conn.close()

    # 회원 생성
    def create_user(self, email: str, password: str, nickname: str | None):
        conn = self.db.get_connection()
        cursor = conn.cursor()
        try:
            # 비밀번호 해시 생성
            pw_hash = bcrypt.hashpw(
                password.encode("utf-8"),
                bcrypt.gensalt()
            ).decode("utf-8")

            cursor.execute(
                """
                INSERT INTO users (email, nickname, password_hash)
                VALUES (%s, %s, %s)
                """,
                (email, nickname, pw_hash)
            )
            conn.commit()
            return True
        except Exception as e:
            print("create_user error:", e)
            conn.rollback()
            return False
        finally:
            cursor.close()
            conn.close()

    # 비밀번호 검증
    def check_password(self, user_row: dict, plain_password: str) -> bool:
        # user_row["password_hash"] 컬럼 이름 꼭 맞춰야 함
        stored_hash = user_row.get("password_hash")
        if not stored_hash:
            return False

        try:
            return bcrypt.checkpw(
                plain_password.encode("utf-8"),
                stored_hash.encode("utf-8")
            )
        except Exception as e:
            print("check_password error:", e)
            return False
