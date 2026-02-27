import urllib.request
import json
import random
import os
from collections import Counter
from datetime import datetime, timedelta

LOTTO_START_DATE = datetime(2002, 12, 7)
CACHE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "lotto_cache.json")


def date_to_round(date):
    diff = date - LOTTO_START_DATE
    return diff.days // 7 + 1


def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_cache(cache):
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)


def fetch_batch(round_list):
    """lotto-haru API로 여러 회차 한번에 조회 (최대 50개씩)"""
    chasu_param = "|".join(str(r) for r in round_list)
    url = f"https://api.lotto-haru.kr/win/analysis.json?chasu={chasu_param}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        print(f"  [!] 조회 실패: {e}")
        return []


def fetch_all_results(start_year=2020, end_year=2026):
    start_round = date_to_round(datetime(start_year, 1, 1))
    end_round = date_to_round(datetime(end_year, 12, 31))

    cache = load_cache()
    cached_rounds = {r["round"] for r in cache.get("results", [])}

    # 캐시에 없는 회차만 추려냄
    missing_rounds = [r for r in range(start_round, end_round + 1) if r not in cached_rounds]

    if not missing_rounds:
        results = cache["results"]
        print(f"💾 캐시에서 {len(results)}회차 데이터 로드 완료! (API 호출 없음)\n")
        return results

    print(f"📡 {start_year}~{end_year}년 로또 당첨번호 조회 중...")
    print(f"   캐시: {len(cached_rounds)}건 / 신규 조회: {len(missing_rounds)}건\n")

    results = list(cache.get("results", []))

    # 50개씩 배치 요청
    batch_size = 50
    new_count = 0
    for i in range(0, len(missing_rounds), batch_size):
        batch = missing_rounds[i:i + batch_size]
        data_list = fetch_batch(batch)
        for d in data_list:
            year = int(d["date"].split("-")[0])
            if start_year <= year <= end_year:
                results.append({
                    "round": d["chasu"],
                    "date": d["date"],
                    "numbers": sorted(d["ball"]),
                    "bonus": d["bonusBall"],
                })
                new_count += 1
        print(f"   ... {batch[-1]}회까지 조회 완료 (신규 {new_count}건)")

    results.sort(key=lambda x: x["round"])

    # 캐시 저장
    save_cache({"updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "results": results})
    print(f"\n✅ 총 {len(results)}회차 데이터 수집 완료! (캐시 저장됨)\n")
    return results


def analyze(results):
    all_numbers = []
    for r in results:
        all_numbers.extend(r["numbers"])

    freq = Counter(all_numbers)
    total = len(results)

    print("=" * 50)
    print(f"📊 당첨번호 통계 분석 (총 {total}회차)")
    print("=" * 50)

    print("\n🔥 가장 많이 나온 번호 TOP 10:")
    for num, count in freq.most_common(10):
        bar = "█" * count
        print(f"   [{num:2d}] {count:3d}회 ({count/total*100:.1f}%) {bar}")

    print("\n❄️  가장 적게 나온 번호 TOP 10:")
    for num, count in freq.most_common()[-10:]:
        bar = "█" * count
        print(f"   [{num:2d}] {count:3d}회 ({count/total*100:.1f}%) {bar}")

    print("\n📈 구간별 출현 비율:")
    ranges = [(1, 10), (11, 20), (21, 30), (31, 40), (41, 45)]
    for start, end in ranges:
        range_count = sum(freq.get(n, 0) for n in range(start, end + 1))
        print(f"   {start:2d}~{end:2d}: {range_count:3d}회 ({range_count/sum(freq.values())*100:.1f}%)")

    return freq


def generate_numbers(freq, count=5):
    numbers = list(range(1, 46))
    weights = [freq.get(n, 0) + 1 for n in numbers]

    print("\n" + "=" * 50)
    print(f"🎰 빈도 기반 추천 번호 ({count}세트)")
    print("=" * 50)

    generated = []
    for i in range(count):
        picked = set()
        while len(picked) < 6:
            chosen = random.choices(numbers, weights=weights, k=1)[0]
            picked.add(chosen)
        picked = sorted(picked)
        generated.append(picked)
        display = "  ".join(f"{n:2d}" for n in picked)
        print(f"   [{i+1}] {display}")

    return generated


def main():
    print("🍀 로또번호 추출기 (2020~2026년 1등 당첨번호 기반)")
    print("=" * 50)
    print()

    results = fetch_all_results(2020, 2026)

    if not results:
        print("❌ 데이터를 가져오지 못했습니다.")
        return

    print("-" * 50)
    print("📋 최근 5회 당첨번호:")
    for r in results[-5:]:
        nums = "  ".join(f"{n:2d}" for n in r["numbers"])
        print(f"   {r['round']:4d}회 ({r['date']}) : {nums}  + {r['bonus']:2d}")
    print("-" * 50)

    freq = analyze(results)
    generate_numbers(freq, count=5)

    print("\n" + "=" * 50)
    print("💡 본 프로그램은 과거 데이터 기반 참고용이며,")
    print("   로또 당첨을 보장하지 않습니다. 행운을 빕니다! 🍀")
    print("=" * 50)


if __name__ == "__main__":
    main()
