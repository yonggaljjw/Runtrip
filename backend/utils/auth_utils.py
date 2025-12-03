# utils/auth_utils.py

import os
from functools import wraps

import jwt
from flask import request, jsonify, current_app


def _get_secret_key() -> str:
    """
    AuthService에서 JWT 만들 때 쓴 것과 동일한 SECRET_KEY 를 사용해야 함.
    보통 app.config['SECRET_KEY'] 또는 환경변수 SECRET_KEY 를 사용한다고 가정.
    """
    return current_app.config.get("SECRET_KEY") or os.environ.get("SECRET_KEY", "dev-secret")


def token_required(fn):
    """
    Authorization 헤더의 Bearer 토큰을 검사하는 데코레이터

    - 헤더 없거나 형식 틀리면 401
    - 토큰 만료 / 검증 실패 시 401
    - 정상일 경우, 디코딩한 payload 를 current_user 인자로 넘김
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")

        if not auth_header.startswith("Bearer "):
            return jsonify({
                "success": False,
                "message": "인증 토큰이 필요합니다."
            }), 401

        token = auth_header.split(" ", 1)[1].strip()

        try:
            payload = jwt.decode(token, _get_secret_key(), algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return jsonify({
                "success": False,
                "message": "로그인이 만료되었습니다. 다시 로그인 해주세요."
            }), 401
        except jwt.InvalidTokenError:
            return jsonify({
                "success": False,
                "message": "유효하지 않은 토큰입니다."
            }), 401

        # current_user 인자로 payload 전달
        kwargs["current_user"] = payload
        return fn(*args, **kwargs)

    return wrapper
