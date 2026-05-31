#Requires AutoHotkey v2.0

/************************************************************************
 * @description 유용한 전역 기능들
 * @author JKAKK
 * @date 2026/05/25
 * @version 0.0.3
 ***********************************************************************/

/** x,y 2차원 자료구조 */
class Vector2d {
    /** @type {Number} */
    x := 0

    /** @type {Number} */
    y := 0

    ; 생성자
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

    IsEqual(&other)
    {
        return this.x == other.x 
            && this.y == other.y
    }

    ToString()
    {
        return Format("x : {1}, y : {2}", this.x, this.y)
    }
}

/** #### 범용 사용 클래스 */
class JKUtilityBase {
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
     * *
     * @see JKUtilityBase.LoadPrioritySheetData | 실사용할때는 이 함수로
     * @param {String} csvFilePath - 시트 전체 경로
     * @param {String} keyHeader - 마스터키로 할 col 이름 | 비지정 시 첫 번째 헤더로 자동 지정
     * @returns {Map} - 맵 [마스터키헤더 : {맵[헤더] : 값}]
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
     * @returns {Map} - 맵 [마스터키헤더 : {맵[헤더] : 값}]
     * @example 
     * sheetData := JKUtilityBase.LoadPrioritySheetData(path, name)
     * name := sheetData["keyHeader"]["name"]
     */
    static LoadPrioritySheetData(csvFolderPath, csvFileName, keyHeader := "")
    {
        priorityAry := [
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

        /** 반환할 시트 데이터  
         * @type {Map} 
         */
        sheetData := Map()

        ; 경로 설정 확인
        if(csvPath = "")
        {
            JKUtility.Log("경로 문제 발생, 폴더 경로 : " csvFolderPath " 파일 이름 : " csvFileName)
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
     * @returns {Class} - 변환된 클래스 데이터
     */
    static MapToClass(mapData, classType) 
    {
        ; 클래스 인스턴스 생성
        local newClassIns := classType() 

        for key, value in mapData 
        {
            local strKey := String(key)

            if (newClassIns.HasProp(strKey)) 
                ; Map의 값을 클래스 속성으로 설정
                newClassIns.%strKey% := value 
        }

        return newClassIns
    }

    /**
     * #### MaterKeyMap 을 maptocalss로 변환한 맵으로 변환
     * 
     * @description {@link JKUtilityBase.LoadSheetData} 에서 반환하는 마스터키를 가진 맵의 값들을 클래스로 변환해서 가지는 맵으로 반환 
     * @param {Map} masterMap - 마스터맵
     * @param {Class} classType - 변환할 클래스
     * @returns {Map} - Map[ 마스터키 : 클래스] 변환된 클래스 인스턴스 맵
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

        ; 디버그 뷰어용
        OutputDebug(fullMsg) 
        ; VS Code 터미널(Stdout) 출력용
        try FileAppend(fullMsg, "*") 
    }

    /**
     * #### 쉼표 문자열 배열 변환후 변환된 데이터 반환
     * 
     * @description , 가 들어간 string이 들어간 데이터를 배열로 변환해주는 재귀
     * @param {Map|Array|String} data - , 가 들어간 string이 있는 맵, 배열, 문자열
     * @returns {Map|Array|String} - 변환된 데이터
     * @example data := JKUtility.ConvertCommaStringToAry(data)
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
}