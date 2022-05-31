d#!/bin/bash
mkdir DBS 2> /dev/null

function mainMenu {
  echo -e "--------------------------------database menu----------------------"
  select ch in selectDb createDb renameDb dropDb showDb exitt
  do
   case $ch in
    selectDb)  selectDB ;;
    createDb)  createDB ;;
    renameDb)  renameDB ;;
    dropDb)  dropDB ;;
    showDb)  ls ./DBS ; mainMenu;;
    exitt) exit ;;
    *) echo " Wrong Choice " ; mainMenu;
  esac
  done
}

function createDB {
  echo -e "enter database name: \c"
  read dbName
  mkdir ./DBS/$dbName 2> /dev/null
  if [[ $? == 0 ]]
  then
    echo "database is created Successfully"
  else
    echo "error in creating database $dbName"
  fi
  clear
  mainMenu
}

function selectDB { 
  echo -e "enter database name: \c"
  read dbName
  cd ./DBS/$dbName 2>  /dev/null
  if [[ $? == 0 ]]; then
    echo "database $dbName is selected Successfully"
    clear
    tablesMenu
  else
    echo "database $dbName isn't found"
    mainMenu
  fi
  
}

function renameDB {
  echo -e "enter current database name: \c"
  read dbName
  echo -e "enter new database name: \c"
  read newName
  mv ./DBS/$dbName ./DBS/$newName 2> /dev/null
  if [[ $? == 0 ]]; then
    echo "database is renamed Successfully"
  else
    echo "error in renaming database"
  fi
  mainMenu
}

function dropDB {
  echo -e "enter database name: \c"
  read dbName
  rm -r ./DBS/$dbName 2> /dev/null
  if [[ $? == 0 ]]; then
    echo "database is dropped Successfully"
  else
    echo "database is not found"
  fi
  mainMenu
}

function tablesMenu {
  echo -e "-----------------------------table menu-------------------------------"
  select ch in show create insert update  delete selectt drop back exitt
  do
  case $ch in
    show)  ls .; tablesMenu ;;
    create)  createTable ;;
    insert)  insert;;
    update)  updateTable;;
    delete)  deleteFromTable;;
    selectt)  clear; selectMenu ;;
    drop)  dropTable;;
    back) clear; cd ../.. 2> /dev/null; mainMenu ;;
    exitt) exit ;;
    *) echo " Wrong Choice " ; tablesMenu ;;
  esac
  done
}

function createTable {
  echo -e "enter table name: \c"
  read tableName
  if [[ -f $tableName ]]; then 
    echo "table '$tableName' already existed ,choose another name"
    tablesMenu
  fi
  echo -e "enter number of columns: \c"
  read colsNum
  counter=1
  sep="|"
  rSep="\n"
  pKey=""
  temp=""
  metaData="Field"$sep"Type"$sep"key"
  while [ $counter -le $colsNum ]
  do
    echo -e "enter name of column no.$counter: \c"
    read colName

    echo -e "enter type of column $colName: "
    select var in "int" "str"
    do
      case $var in
        int ) colType="int";break;;
        str ) colType="str";break;;
        * ) echo "Wrong Choice" ;;
      esac
    done
    if [[ $pKey == "" ]]; then
      echo "make it a primary key ? "
      select var in "yes" "no"
      do
        case $var in
          yes ) pKey="PK";
          metaData+=$rSep$colName$sep$colType$sep$pKey;
          break;;
          no )
          metaData+=$rSep$colName$sep$colType
          break;;
          * ) echo "Wrong Choice" ;;
        esac
      done
    else
      metaData+=$rSep$colName$sep$colType$sep
    fi

    if [[ $counter == $colsNum ]]; then
      temp=$temp$colName
    else
      temp=$temp$colName$sep
    fi
    ((counter++))
  done
  touch .$tableName
  echo -e $metaData >> .$tableName
  touch $tableName
  echo -e $temp >> $tableName
  if [[ $? == 0 ]]
  then
    echo "table is created Successfully"
    tablesMenu
  else
    echo "error in creating table $tableName"
    tablesMenu
  fi
}

function insert {
  echo -e "enter table name: \c"
  read tableName
  if ! [[ -f $tableName ]]; then
    echo "table $tableName isn't existed so choose another table"
    tablesMenu
  fi
  colsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $colsNum; i++ ))
   do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo -e "$colName ($colType) = \c"
    read data
    # Validate 
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "invalid datatype !!"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi
  #--------------------------------------------
    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $colType == "int" ]]; then
          while ! [[ $data =~ ^[0-9]*$ ]]; do
            echo -e "invalid datatype !!"
            echo -e "$colName ($colType) = \c"
            read data
          done
        fi
        awkres=`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName` # [1 2 3 4 5 ]
        if [[ "${awkres[*]}" =~ "$data" || "$data" == " " ]]; then 
          echo -e "invalid value for Primary Key !!"
          echo -e "$colName ($colType) = \c"
          read data
        else
          break;
        fi
      done
    fi
  #-------------------------------------------
    #Set row
    # row="lol|kok"
    if [[ $i == $colsNum ]]; then
      row=$row$data
    else
      row=$row$data$sep
    fi
  done
  echo $row >> $tableName
  if [[ $? == 0 ]]
  then
    echo "data is inserted Successfully"
  else
    echo "error in Inserting data into table $tableName"
  fi
  row=""
  tablesMenu
}

function updateTable {
  echo -e "enter table name: \c"
  read tName
  if ! [[ -f $tName ]]; then
    echo "Table $tName isn't existed ,choose another Table"
    tablesMenu
  fi
  echo -e "enter column name: \c"
  read field

  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Field is not Found"
    tablesMenu
  else
    echo -e "enter wanted value: \c"
    read val
    oldValue=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2> /dev/null)
    if [[ $oldValue == "" ]]
    then
      echo "value is not found"
      tablesMenu
    else
        NR=$(awk 'BEGIN{FS="|"}{if( NR != 1 && $'$fid' == "'$val'") print NR}' $tName 2> /dev/null)
        colType=`awk 'BEGIN{FS="|"}{if(NR ==  (('$fid'+1)) ) print $2}' .$tName`
        colKey=`awk 'BEGIN{FS="|"}{if(NR == (('$fid'+1)) )  print $3}' .$tName`
        echo -e "Enter new Value to set: \c"
        read newValue
        #--------------------------
        # echo "Hello => " $colType $colKey $tName
        # echo "Hi => " $NR
        # Validate Input
      if [[ $colType == "int" ]]; then
        while ! [[ "$newValue" =~ ^[0-9]*$ ]]; do
          echo -e "invalid DataType !!"
          echo -e "enter new value to set: \c"
          read newValue
        done
      fi
  #--------------------------------------------
      if [[ $colKey == "PK" ]]; then
        while [[ true ]]; do
            if [[ $colType == "int" ]]; then
            while ! [[ "$newValue" =~ ^[0-9]*$ ]]; do
            echo -e "invalid data type !!"
            echo -e "enter new value to set: \c"
            read newValue
            done
            fi
          awkres=`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $'$fid'}' $tName` #old values
          if [[ "${awkres[*]}" =~ "$newValue" || "$newValue" == " " ]]; then 
            echo -e "invalid value for Primary Key !!"
            echo -e "enter new value to set: \c"
            read newValue
          else
            break;
          fi
        done
      fi
  #------------------------------------------
        sed -i ''$NR's/'$oldValue'/'$newValue'/g' $tName 2> /dev/null
        echo "row is updated Successfully '$oldValue'"
        tablesMenu
    fi
  fi
}

function deleteFromTable {
  echo -e "enter table name: \c"
  read tName
  if ! [[ -f $tName ]]; then
    echo "table $tName isn't existed so choose another table"
    tablesMenu
  fi
  echo -e "enter column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName) 
  if [[ $fid == "" ]]
  then
    echo "field is not found"
    tablesMenu
  else
    echo -e "enter wanted value: \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2> /dev/null) 
    if [[ $res == "" ]]
    then
      echo "value  is not Found"
      tablesMenu
    else
      NR=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print NR}' $tName 2> /dev/null)
      sed -i ''$NR'd' $tName 2> /dev/null
      echo "row deleted Successfully"
      tablesMenu
    fi
  fi
}

function dropTable {
  echo -e "enter table name: \c"
  read tName
  rm $tName .$tName 2> /dev/null
  if [[ $? == 0 ]]
  then
    echo "table is dropped Successfully"
  else
    echo "error in dropping table $tName"
  fi
  tablesMenu
}
function selectMenu {
  echo -e "\n---------------select menu--------------------"
  # select ch in selectAllCols selectColByNumber selectColByName getmatchedvaluesByrow getmatchedvaluesBycol tableMenu mainMenu exitt
  select ch in selectAll selectColByName getmatchedvaluesByrow getmatchedvaluesBycol tableMenu mainMenu exitt
  do
   case $ch in
    selectAll )clear; selectAll ;;
    selectColByName)clear; selectColByName ;;
    getmatchedvaluesByrow) clear; getmatchedvaluesByrow ;;
    getmatchedvaluesBycol) clear; getmatchedvaluesBycol ;;
    tableMenu) clear; tablesMenu ;;
    mainMenu) clear; cd ../.. 2> /dev/null; mainMenu ;;
    exitt) exit ;;
    *) echo " Wrong Choice " ; selectMenu;
  esac
  done

}

function selectAll {
  echo -e "enter table name: \c"
  read tName
    if ! [[ -f $tName ]]; then
    echo "table $tName isn't existed ,choose another Table"
    selectMenu
  fi
  column -t -s '|' $tName 2> /dev/null
  if [[ $? != 0 ]]
  then
    echo "error in displaying table $tName"
  fi
  selectMenu
}

function selectColByName {
  echo -e "enter table name: \c"
  read tName
  if ! [[ -f $tName ]]; then
    echo "table $tName isn't existed ,choose another Table"
    selectMenu
  fi
  echo -e "enter column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "column is not Found"
    selectMenu
   else 
  awk 'BEGIN{FS="|"}{print $'$fid'}' $tName
  selectMenu
  fi
}

function getmatchedvaluesByrow {
  echo -e "Select all columns from table Where column(operator)value \n"
  echo -e "enter table name: \c"
  read tName
  if ! [[ -f $tName ]]; then
    echo "table $tName isn't existed ,choose another Table"
    selectMenu
  fi
  echo -e "enter wanted column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "column isn't Found"
    selectMenu
  else
    echo -e "\nOperators: [==, !=, >, <, >=, <=] \nSelect operator: \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nenter wanted value: \c"
      read val
      res=$(awk 'BEGIN{FS="|"}{if ($'$fid'$op$val) print $0}' $tName 2> /dev/null | column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "value isn't Found"
        selectMenu
      else
        awk 'BEGIN{FS="|"}{if ($'$fid$op$val') print $0}' $tName 2> /dev/null |  column -t -s '|'
        selectMenu
      fi
    else
      echo "unsupported Operator\n"
      selectMenu
    fi
  fi
}

function getmatchedvaluesBycol {
  echo -e "Select specific column from table Where column(operator)value \n"
  echo -e "enter table name: \c"
  read tName
  echo -e "enter required column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "value isn't Found"
    selectMenu
  else
    echo -e "\nOperators: [==, !=, >, <, >=, <=] \nSelect operator: \c"
    read op
    if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]
    then
      echo -e "\nenter wanted value: \c"
      read val
      res=$(awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2> /dev/null |  column -t -s '|')
      if [[ $res == "" ]]
      then
        echo "value isn't Found"
        selectMenu
      else
        awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$fid$op$val') print $'$fid'}' $tName 2> /dev/null |  column -t -s '|'
        selectMenu
      fi
    else
      echo "unsupported Operator\n"
      selectMenu
    fi
  fi
}

mainMenu