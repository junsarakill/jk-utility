#Requires AutoHotkey v2.0

/************************************************************************
 * @description 유용한 전역 기능들
 * @author JKAKK
 * @date 2026/05/25
 * @version 0.0.3
 ***********************************************************************/

/** x,y 2차원 자료구조 */
class Vector2d 
{
    /** @type {Number} */
    x := 0

    /** @type {Number} */
    y := 0

    /**
     * #### 생성자
     * *
     * @param {Number} x - x 좌표
     * @param {Number} y - y 좌표
     * @returns {void}
     */
    __New(x := 0, y := 0) {
        this.x := x
        this.y := y
    }

    ; * 연산자
    Multiply(other)
    {
        if(other is Vector2d)
        {
            return Vector2d(this.x * other.x
                            ,this.y * other.y)
        }
        else if(other is Number)
        {
            return Vector2d(this.x * other
                            ,this.y * other)
        }
    }

    IsEqual(&other)
    {
        return this.x == other.x 
            && this.y == other.y
    }

    ToString()
    {
        return Format("x : {1}, y : {2}", this.x, this.y)
    }

    ; hwnd 받아서 해당 창의 크기를 가져옴.
    static WinGetClientSize(targetHwnd)
    {
        WinGetClientPos(, , &outW, &outH, targetHwnd)

        return Vector2d(outW, outH)
    }
}

/** #### 범용 사용 클래스 */
class JKUtilityBase 
{
    ; MARK: 전역 변수 단
    
    /** @type {String} */
    static _sheetFolder := A_ScriptDir . "\Sheet\" 
    /**
     * #### 시트 폴더 경로
     * @type {String} 
     */
    static SHEET_FOLDER => this._sheetFolder

    /** @type {String} */
    static _sheetEXT := ".csv"
    /**
     * #### 시트 확장자
     * @type {String} 
     * @example asd := this.SHEET_FOLDER . gameName . this.SHEET_EXT
     */
    static SHEET_EXT => this._sheetEXT
    
    ; MARK: 전역 함수 단

    /**
     * #### CSV 한 줄 파싱
     * *
     * @description row 안 값에 , 나 " 가 있을 경우를 처리
     * @param {String} line - csv row 한 개
     * @returns {Array} - 파싱된 배열
     */
    static ParseCSVLine(line) 
    {
        /** @type {Array} */
        result := []

        loop parse, line, "CSV"
        {
            result.Push(A_LoopField)
        }

        return result
    }

    /**
     * #### 시트 데이터를 마스터키를 가진 맵으로 불러오기
     * @see JKUtilityBase.LoadPrioritySheetData | 실사용할때는 이 함수로
     * @param {String} csvFilePath - 시트 전체 경로
     * @param {String} keyHeader - 마스터키로 할 col 이름 | 비지정 시 첫 번째 헤더로 자동 지정
     * @returns {Map<String, Map<String, String>>} - 맵 [마스터키헤더 : {맵[헤더] : 값}]
     */
    static LoadSheetData(csvFilePath, keyHeader := "")
    {
        csvData := FileRead(csvFilePath, "UTF-8")

        ; 행 분리
        rows := StrSplit(csvData, "`n", "`r")
    
        ; 헤더 가져오기
        /** @type {Array} */
        headers := this.ParseCSVLine(rows[1])
        ; 마스터 키 지정 없으면 가져오기
        if(keyHeader = "")
            keyHeader := headers[1]
    
        ; 시트 구분해서 구조체(map을 가진 배열)에 저장
        dataMap := Map()
        
        for i, row in rows 
        {
            if(i = 1 || row = "")
                continue
            /** @type {Array} */
            rowData := this.ParseCSVLine(row)
            field := Map()
            masterKey := unset

            for index, header in headers 
            {
                ; rowData[index]가 존재하면 넣고, 없으면 빈 값 처리
                value := (rowData.Has(index) 
                        ? rowData[index] : "")

                ; 마스터 키의 값 가져오기
                if(header = keyHeader)
                    masterKey := value                
                ; class 로 변환 고려해서 헤더, 값을 전부 저장
                field[header] := value
            }

            if(IsSet(masterKey))
                dataMap[masterKey] := field
        }
    
        return dataMap
    }
    
    /**
     * #### 우선 순위 있는 시트 데이터 불러오기
     * 
     * @description 로컬 설정 및 공통 기본값 파일의 우선순위를 고려하여 
     * 시트 데이터를 탐색하고 구조체로 변환하여 불러옵니다.
     * 
     * **[파일 탐색 순서]**
     * 1. `{folderPath}/{fileName}.{ext}` (분리 없는 파일 - 최우선)
     * 2. `{folderPath}/{fileName}.local.{ext}` (개별 설정 파일)
     * 3. `{folderPath}/{fileName}.default.{ext}` (공통 기본값 파일 - 최하위)
     * @param {String} csvFolderPath - 시트 폴더 경로
     * @param {String} csvFileName - 시트 파일 이름 (확장자 없이)
     * @param {String} keyHeader - 마스터키로 할 col 이름 | 비지정 시 첫 번째 헤더로 자동 지정
     * @returns {Map<Stirng, Map<String,String>>} - 맵 [마스터키헤더 : {맵[헤더] : 값}]
     * @example 
     * sheetData := JKUtilityBase.LoadPrioritySheetData(path, name)
     * name := sheetData["keyHeader"]["name"]
     */
    static LoadPrioritySheetData(csvFolderPath, csvFileName, keyHeader := "")
    {
        ; 파일 경로
        csvPath := this.GetPriorityFilePath(csvFolderPath, csvFileName)

        /** 반환할 시트 데이터  
         * @type {Map} 
         */
        sheetData := Map()

        ; 경로 설정 확인
        if(csvPath = "")
        {
            JKUtilityBase.Log("경로 문제 발생, 폴더 경로 : " csvFolderPath " 파일 이름 : " csvFileName)
            return sheetData
        }
    
        ; 해당 경로로 시트 데이터 받기
        sheetData := this.LoadSheetData(csvPath, keyHeader)

        return sheetData
    }
    
    ; 관리자 권한 체크 및 재실행
    static RunAdmin()
    {
        if !A_IsAdmin
        {
            Run('*RunAs "' A_AhkPath '" /Restart "' A_ScriptFullPath '"')
            ExitApp()
        }
    }

    /**
     * #### map 데이터 => 클래스 로 변환
     * *
     * @param {Map} mapData - 변환할 map 데이터
     * @param {Class} classType - 반환할 클래스 타입
     * @param {Array} newArgs - 생성자에 넣을 값들
     * @returns {Class} - 변환된 클래스 데이터
     */
    static MapToClass(mapData, classType, newArgs*) 
    {
        ; 클래스 인스턴스 생성
        local newClassIns := classType(newArgs*) 

        for key, value in mapData 
        {
            local strKey := String(key)

            ; 재귀 탐색해서 속성에 값 주입
            if(!this.AssignValueToProp(newClassIns, strKey, value))
            {
                ; 탐색 실패함
                JKUtilityBase.Log("해당 프로퍼티 주입 실패 : 클래스 타입 " Type(classType) " 프로퍼티명 " strKey " 값 " value)
            }
        }

        return newClassIns
    }

    ; 객체를 재귀적으로 탐색하며 프로퍼티 이름 일치하면 값 주입
    static AssignValueToProp(targetObj, targetKey, value)
    {
        ; 프로퍼티 존재 확인
        if(targetObj.HasProp(targetKey))
        {
            ; 값 주입
            targetObj.%targetKey% := value

            return true
        }

        ; 없다면, 현재 객체에 서브 클래스 존재 탐색
        for propName in targetObj.OwnProps()
        {
            local propObj := targetObj.%propName%

            ; 객체면 내부 진입
            if(IsObject(propObj) 
            && !(propObj is Map) 
            && !(propObj is Array)
            && !(propObj is Func)
            && !(propObj is Buffer)
            )
            {
                if(this.AssignValueToProp(propObj, targetKey, value))
                {
                    return true
                }
            }
        }

        ; 해당 프로퍼티 탐색 실패
        return false
    }

    /**
     * #### MaterKeyMap 을 maptocalss로 변환한 맵으로 변환
     * 
     * @description {@link JKUtilityBase.LoadSheetData} 에서 반환하는 마스터키를 가진 맵의 값들을 클래스로 변환해서 가지는 맵으로 반환 
     * @param {Map} masterMap - 마스터맵
     * @param {Class} classType - 변환할 클래스
     * @returns {Map<String, Class>} - Map[ 마스터키 : 클래스] 변환된 클래스 인스턴스 맵
     */
    static MasterMapToClassMap(masterMap, classType)
    {
        /** @type {Map} */
        classInsMap := Map()

        for masterKey, rowMap in masterMap
        {
            ; 각 행의 map을 클래스 변환
            classInsMap[masterKey] := JKUtilityBase.MapToClass(rowMap, classType)
        }

        return classInsMap
    }

    /**
     * #### MaterKeyMap 을 maptocalss로 변환한 배열로 변환
     * 
     * @description {@link JKUtilityBase.LoadSheetData} 에서 반환하는 마스터키를 가진 맵의 값들을 클래스로 변환해서 가지는 배열로 반환 
     * @param {Map} masterMap - 마스터맵
     * @param {Class} classType - 변환할 클래스
     * @returns {Array} - Array[클래스] 변환된 클래스 인스턴스 배열
     */
    static MasterMapToClassAry(masterMap, classType)
    {
        /** @type {Array} */
        classAry := []

        for , rowMap in masterMap
        {
            classAry.Push(JKUtilityBase.MapToClass(rowMap,classType))
        }

        return classAry
    }

    /**
     * #### 디버그 로그 용 메시지 출력
     * *
     * @param {String} msg - 메시지 문자열
     * @returns {void} - 반환값 설명
     * @example JKUtility.Log("asd")
     */
    static Log(msg) 
    {
        ; 로그 호출 위치
        logLocation := Error("", -1)
        SplitPath(logLocation.File, &fileName)

        fullMsg := msg " <== [ " fileName ":" logLocation.Line "]`n" 

        ; ; 디버그 뷰어용
        ; OutputDebug(fullMsg) 
        ; VS Code 터미널(Stdout) 출력용
        try FileAppend(fullMsg, "*") 
    }

    /**
     * #### 쉼표 문자열 배열 변환
     * 
     * @description , 가 들어간 string이 들어간 데이터를 배열로 변환해주는 재귀
     * @param {Map|Array|String} data - , 가 들어간 string이 있는 맵, 배열, 문자열
     * @returns {Map|Array|String} - 변환된 데이터
     * @example convertedData := JKUtility.ConvertCommaStringToAry(data)
     */
    static ConvertCommaStringToAry(data)
    {
        if(data is Map)
        {
            ; 원본 Map의 오염 및 순회 중 수정 에러를 방지하기 위해 새 Map 생성
            resMap := Map()
            for key, value in data
            {
                resMap[key] := this.ConvertCommaStringToAry(value)
            }

            return resMap
        }
        else if(data is Array)
        {
            ; 원본 Array의 오염을 방지하기 위해 새 Array 생성
            resAry := []
            for , value in data
            {
                resAry.Push(this.ConvertCommaStringToAry(value))
            }
            return resAry
        }
        ; 쉼표 포함 문자열일 경우 배열 변환
        else if(data is String && InStr(data, ","))
            return StrSplit(data, ",", " ")
        
        ; 결과물 or 비대상 데이터 반환
        return data
    }

    /**
     * #### 시스템 커서 표시
     * @param {Bool} value - 표시 유무
     */
    static SetVisibleCursor(value)
    {
        ; OCR_NORMAL (일반 화살표 커서 ID)
        static OCR_NORMAL := 32512
        static orgCursorCopy := 0

        if (!value && orgCursorCopy = 0)
        {
            curCursorHwnd := DllCall("GetCursor", "Ptr")
            
            ; 원래 커서가 사라지지 않도록 복사본 저장
            orgCursorCopy := DllCall("CopyIcon", "Ptr", curCursorHwnd, "Ptr")

            ; 투명 커서 생성 | (CreateCursor 대신 시스템이 제공하는 안전한 빈 커서 마스크 활용)
            blankCursor := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0, "Int", 32, "Int", 32, "Ptr", Buffer(32 * 4, 0xFF).Ptr, "Ptr", Buffer(32 * 4, 0x00).Ptr, "Ptr")

            ; 시스템 커서를 빈 커서로 교체
            DllCall("SetSystemCursor", "Ptr", blankCursor, "Int", OCR_NORMAL)
        }
        else if(orgCursorCopy != 0)
        {
            ; 백업 커서로 복구
            DllCall("SetSystemCursor", "Ptr", orgCursorCopy, "Int", OCR_NORMAL)
            
            ; SPI_SETCURSORS (0x0057): 시스템 커서 변경 사항을 전역에 즉시 새로고침
            DllCall("SystemParametersInfo", "UInt", 0x0057, "UInt", 0, "Ptr", 0, "UInt", 0)
            
            ; 복사본 제거
            orgCursorCopy := 0
        }
    }

    /**
     * #### 지속 시간 있는 툴팁
     * @param {String} text - 툴팁 텍스트
     * @param {Number} duration - 지속시간
     * @returns {void} - 
     */
    static JKTooltip(text := "", duration := 0)
    {
        ; 최신 툴팁 검사용 토큰
        static curToken := 0

        ToolTip(text)
        curToken++
        thisToken := curToken

        ; 지속 시간 기입시 제거하는 타이머 바인딩
        if(duration)
        {
            SetTimer(() => (
                ; 타이머 실행 시점에 내 토큰이 여전히 '최신 토큰'인 경우에만 끄기
                (thisToken = curToken) ? ToolTip() : 0
            ), -duration)
        }
    }

    /**
     * #### 우선 순위 있는 파일 탐색
     * **[파일 탐색 순서]**
     * 1. `{folderPath}/{fileName}.{ext}` (분리 없는 파일 - 최우선)
     * 2. `{folderPath}/{fileName}.local.{ext}` (개별 설정 파일)
     * 3. `{folderPath}/{fileName}.default.{ext}` (공통 기본값 파일 - 최하위)
     * @param {String} csvFolderPath - 시트 폴더 경로
     * @param {String} csvFileName - 시트 파일 이름 (확장자 없이)
     * @returns {String} - 파일 전체 경로
     */
    static GetPriorityFilePath(csvFolderPath, csvFileName)
    {
        static priorityAry := [
            ""
            ,".local"
            ,".default"
        ]

        ; 조합될 경로
        csvPath := ""
        ; 우선순위 순 파일 탐색
        for curPR in priorityAry
        {
            ; 경로 조합
            curCSVPath := csvFolderPath . csvFileName . curPR . this.SHEET_EXT
    
            ; 존재확인 
            if(FileExist(curCSVPath))
            {
                ; 있으면 해당 경로 확정 포 종료
                csvPath := curCSVPath
                break
            }
        }

        return csvPath
    }

    static CallMulticastDel(delAry, params*)
    {
        if(!delAry || !HasMethod(delAry, "__Enum"))
            return

        for callback in delAry
        {
            if(HasMethod(callback, "Call"))
                callback(params*)
        }
    }
}