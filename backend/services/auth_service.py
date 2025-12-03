# backend/services/auth_service.py

import os
import jwt
from datetime import datetime, timedelta
from flask import current_app


class AuthService:
    def __init__(self, user_model):
        self.user_model = user_model

    def _get_secret_key(self):
        return current_app.config.get("SECRET_KEY") or os.environ.get(
            "SECRET_KEY", "dev-secret"
        )

    def login(self, email, password):
        user = self.user_model.get_by_email(email)

        if not user:
            return None, "가입되지 않은 이메일입니다."

        if not self.user_model.check_password(user, password):
            return None, "비밀번호가 올바르지 않습니다."

        user_id = user.get("id") or user.get("user_id")

        payload = {
            "user_id": user_id,
            "email": user.get("email"),
            "nickname": user.get("nickname"),
            # 원하면 토큰에도 넣을 수 있음
            "running_level": user.get("running_level"),
            "city": user.get("city"),
            "exp": datetime.utcnow() + timedelta(days=7),
        }

        token = jwt.encode(payload, self._get_secret_key(), algorithm="HS256")

        # 🔹 프론트에 내려줄 user 정보에 running_level, city 포함
        return {
            "token": token,
            "user": {
                "id": user_id,
                "email": user.get("email"),
                "nickname": user.get("nickname"),
                "running_level": user.get("running_level"),
                "city": user.get("city"),
            },
        }, None

    # 회원가입
    def signup(self, data):
        email = data.get("email")
        password = data.get("password")
        nickname = data.get("nickname")

        if not email or not password:
            return False, "이메일과 비밀번호는 필수입니다."

        if self.user_model.get_by_email(email):
            return False, "이미 가입된 이메일입니다."

        if not self.user_model.create_user(email, password, nickname):
            return False, "회원가입 중 오류가 발생했습니다."

        return True, "회원가입이 완료되었습니다."
