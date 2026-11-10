# 개봉역 전월세 레이더

개봉역 주변(구로구 개봉동·고척동·오류동) 아파트·오피스텔·빌라의 **실제 전월세 계약**을 매일 모아
핸드폰에서 보는 웹앱입니다. 홈 화면에 추가하면 일반 앱처럼 열립니다.

- 데이터: 서울 열린데이터광장 「서울시 부동산 전월세가 정보」 (공식 신고 자료, 매일 갱신)
- 지금 나와 있는 **매물**은 앱의 "매물 보기" 탭에서 네이버 부동산·KB·호갱노노·직방·다방으로 바로 이동
  (이 사이트들은 자동 수집을 막고 있어서 앱이 직접 긁어오지 않습니다)

## 파일 구성
| 파일 | 역할 |
|---|---|
| `update.ps1` | 데이터 수집 (PowerShell, 별도 설치 불필요) → `docs/data.js` 생성 |
| `docs/index.html` | 핸드폰용 화면 |
| `.github/workflows/update.yml` | GitHub에서 매일 아침 7시 자동 갱신 |

## 1단계: 무료 인증키 받기 (5분)
1. https://data.seoul.go.kr 회원가입 → 로그인
2. 상단 "이용안내 → Open API 소개 → 인증키 신청" (일반 인증키)
3. 받은 키를 이 폴더에 `apikey.txt` 파일로 저장 (첫 줄에 키만)
4. PC에서 실행해 보기:
   ```
   powershell -ExecutionPolicy Bypass -File update.ps1
   ```
   그 다음 `docs/index.html`을 브라우저로 열면 전체 데이터가 보입니다.

## 2단계: 핸드폰에서 매일 갱신되게 (GitHub, 무료)
1. https://github.com 가입 → 새 저장소(repository) 만들기 (Public, 이름 예: `rent-radar`)
2. 이 폴더 내용을 그대로 업로드 (`apikey.txt`는 올리지 마세요)
3. 저장소 **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `SEOUL_API_KEY` / Value: 인증키
4. **Settings → Pages** → Source: `Deploy from a branch`, Branch: `main`, 폴더 `/docs` → Save
5. **Actions** 탭 → `daily-update` → `Run workflow` 로 한 번 실행해 확인
6. 핸드폰에서 `https://<아이디>.github.io/rent-radar/` 접속 →
   - 아이폰: 사파리 공유 버튼 → "홈 화면에 추가"
   - 안드로이드: 크롬 메뉴 → "홈 화면에 추가"

이후 매일 아침 7시에 자동으로 새 계약이 반영됩니다. 앱을 열면 지난 방문 이후 새로 들어온 계약에 **NEW** 표시가 붙습니다.

> 주의: 저장소가 Public이면 앱 주소를 아는 사람은 누구나 볼 수 있습니다 (공공데이터라 민감정보는 없음).
> 인증키는 Secret에만 넣으면 공개되지 않습니다.

## 앱 사용 팁
- **월 환산비용** = 월세 + 보증금 × 전환율 ÷ 12. 전세/반전세/월세를 같은 잣대로 비교합니다.
  설정 탭에서 지금 집(기본값 보증금 5,000 / 월 130)과 전환율을 바꿀 수 있어요.
- **단지별** 탭: 건물별 전세·월세 중간값. 누르면 그 건물 계약만 모아 봅니다.
- 계약 신고는 계약 후 30일 이내라 최근 며칠치는 늦게 채워질 수 있습니다.
