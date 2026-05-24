#Requires AutoHotkey v2.0

/************************************************************************
 * @description 유용한 전역 기능들
 * @author JKAKK
 * @date 2026/05/19
 * @version 0.0.2
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

    ; @@ 데이터에 큰 따옴표가 직접 들어가면 "" 으로 표기되서 망가질 수 있음. 개선여지
    ; CSV 한 줄 파싱
    static ParseCSVLine(line) 
    {
        result := []
        currentField := ""
        ; 현재 "" 안에 있음 여부
        inQuotes := false
        
        loop parse, line 
        {
            char := A_LoopField
            
            ; 따옴표를 만나면 상태를 반전
            if (char == '"') 
                inQuotes := !inQuotes
            ; 따옴표 밖에서 쉼표를 만나면 필드 구분
            else if (char == ',' && !inQuotes) 
            {
                result.Push(currentField)
                currentField := ""
            } 
            ; 그 외의 문자는 필드에 추가
            else 
                currentField .= char
        }

        ; 마지막 필드 추가
        result.Push(currentField) 
        return result
    }

    /**
     * #### 시트 데이터 구조체로 변환하기
     * *
     * @see JKUtility.LoadPrioritySheetData | 실사용할때는 이 함수로
     * @param {String} csvFilePath - 시트 전체 경로
     * @returns {Map} - 배열 { 맵[헤더] : 값 } 시트 데이터
     */
    static LoadSheetData(csvFilePath, keyHeader := "")
    {
        csvData := FileRead(csvFilePath, "UTF-8")

        ; 행 분리
        rows := StrSplit(csvData, "`n", "`r")
    
        ; 헤더 가져오기
        headers := this.ParseCSVLine(rows[1])
        ; 마스터 키 가져오기
        if(keyHeader = "")
            keyHeader := headers[1]
    
        ; 시트 구분해서 구조체(map을 가진 배열)에 저장
        dataMap := Map()
        
        for i, row in rows 
        {
            if(i = 1 || row = "")
                continue

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
     * *
     * @param {String} csvFolderPath - 시트 폴더 경로
     * @param {String} csvFileName - 시트 파일 이름 (확장자 없이)
     * @returns {Map} - 시트 데이터를 배열 { 맵[헤더] : 값 } 형태로 반환
     * @example 
     * sheetData := this.LoadPrioritySheetData(path, name)
     * for row in sheetData
     * {
     *     someValue := row["header"]
     * }
     */
    static LoadPrioritySheetData(csvFolderPath, csvFileName, keyHeader := "")
    {
        /** 탐색순서
         * {folderPath}/{fileName}.{ext} (분리없는 파일)
        {folderPath}/{fileName}.local.{ext} (개별 설정)
        {folderPath}/{fileName}.default.{ext} (공통 기본값)
         */
        priorityAry := [
            ""
            ,".local"
            ,".default"
        ]
    
        ; 조합될 경로
        csvPath := ""
        ; 배열로 해서 포 돌리기
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
    
        ; 반환할 시트 데이터
        sheetData := []
    
        ; 경로 유효 확인
        if(csvPath != "")
        {
            ; 해당 경로로 시트 데이터 받기
            sheetData := this.LoadSheetData(csvPath, keyHeader)
        }
        ; 결과 리턴
    
        return sheetData
    }
    
    ; vs code 디버그할때는 vs code를 관리자 권한으로 실행
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
        local newClassIns := classType() ; 클래스 인스턴스 생성

        for key, value in mapData {
            local strKey := String(key)

            if (newClassIns.HasProp(strKey)) 
                newClassIns.%strKey% := value ; Map의 값을 클래스 속성으로 설정
        }

        return newClassIns
    }

    ; 
    ; 
    /**
     * #### MaterKeyMap 을 maptocalss로 변환
     * 
     * @description {@link JKUtilityBase.LoadSheetData} 에서 반환하는 마스터키를 가진 맵의 값들을 클래스로 변환해서 가지는 맵으로 반환 | 구조 Map[ 마스터키 : 클래스 ]
     * @param {Map} masterMap - 마스터맵
     * @param {Class} classType - 변환할 클래스
     * @returns {Map} - 변환된 클래스 인스턴스 맵
     */
    static MasterMapToClassMap(masterMap, classType)
    {
        classInsMap := Map()
        for masterKey, rowMap in masterMap
        {
            ; 각 행의 map을 클래스 변환
            classInsMap[masterKey] := JKUtilityBase.MapToClass(rowMap, classType)
        }

        return classInsMap
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

        fullMsg := msg . " <== [ " . fileName . ":" . logLocation.Line . "]`n" 

        OutputDebug(fullMsg) ; 디버그 뷰어용
        try FileAppend(fullMsg, "*") ; VS Code 터미널(Stdout) 출력용
    }

    /**
     * #### , 가 들어간 string이 들어간 데이터를 배열로 변환해주는 재귀
     * *
     * @param {Object} data - , 가 들어간 string이 있는 맵, 배열, 문자열
     * @returns {Object} - 변환된 데이터
     */
    static ConvertCommaStringToAry(data)
    {
        if(data is Map)
        {
            for key, value in data
            {
                data[key] := this.ConvertCommaStringToAry(value)
            }
        }
        else if(data is Array)
        {
            for i, value in data
            {
                data[i] := this.ConvertCommaStringToAry(value)
            }
        }
        ; 문자열일 경우 배열 변환
        else if(Type(data) = "String" && InStr(data, ","))
        {
            return StrSplit(data, ",")
        }
        
        ; 결과물 or 비대상 데이터 반환
        return data
    }
}