# routes/course_route.py

from flask import Blueprint, request, jsonify
from database import Database
from utils.auth_utils import token_required   # ✅ 여기 추가

course_bp = Blueprint("course", __name__)
db = Database()

@course_bp.route("/courses", methods=["GET"])
@token_required   # ✅ 토큰 필수
def get_courses(current_user):
    """
    현재 로그인한 사용자만 코스 목록을 볼 수 있게 하는 엔드포인트.
    current_user 는 JWT payload (예: {"user_id": 1, "email": "..."} )
    """
    # 필요하면 user_id 써서 사용자별 추천 같은 것도 가능
    # user_id = current_user.get("user_id")

    city = request.args.get("city")          # 예: '서울특별시'
    district = request.args.get("district")  # 예: '양천구'

    conn = db.get_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        query = """
            SELECT
                course_id,
                course_name,
                ctprvn_name,
                emndn_name,
                total_length,
                ST_AsText(geometry_wkt) AS geometry_wkt
            FROM running_course2
            WHERE 1=1
        """
        params = []

        if city:
            query += " AND ctprvn_name = %s"
            params.append(city)

        if district:
            query += " AND emndn_name LIKE %s"
            params.append(f"%{district}%")

        query += " LIMIT 50"

        cursor.execute(query, params)
        rows = cursor.fetchall()

        return jsonify({"success": True, "courses": rows}), 200

    except Exception as e:
        print("DB error:", e)
        return jsonify({"success": False, "message": "코스 조회 중 오류가 발생했습니다."}), 500

    finally:
        cursor.close()
        conn.close()
