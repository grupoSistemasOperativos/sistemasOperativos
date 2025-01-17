mostrarAyuda(){
    
    if [[ ($1 == "-h") || ($1 == "-help") || ($1 == "-?") ]]
    then
        echo "Uso: $0 [FILE]"
        echo ""
        echo "Argumentos obligatorios:"
        echo ""
        echo "      -in [FILE] se debe indicar un archivo (ruta relativa, absoluta o con espacios)."
        exit 0
    fi
    
}

generarNombresArchivos(){

    path=$(grep -P -o ".*(?:\/)" <<< "$1")
    nombreArchivo=$(grep -o -P "(?<=\/)+.[^\/]*$" <<< "$1")
    extension=$(grep -o -P "(?<=.\.).+" <<< "$nombreArchivo")
    if [[ $extension != "" ]]
    then
        nombreArchivo=$(grep -o -P ".+(?=\.\w+)" <<< "$nombreArchivo")
        extension=."$extension"
    fi
    fechaYHora=_$(date +%Y%m%d%H%m)

    pathLog="$path""$nombreArchivo"$fechaYHora".log"
    pathCompleto="$path""$nombreArchivo"$fechaYHora"$extension"
}

validarParametros(){
    if [[ $1 != "-in" ]]
    then
        echo "Error, se debe indicar -in como primer parametro"
        exit 1
    fi

    if [[ "$2" == "" ]]
    then
        echo "Error, debe indicar, como segundo parametro, el archivo a corregir"
        exit 1
    fi

    if [[ ! -r "$2" ]]
    then
        echo "Error, \"$2\" no tiene permisos de lectura"
        exit 1
    fi

    if [[ ! -f "$2" ]]
    then
        echo "Error, \"$2\" no es un archivo"
        exit 1
    fi

    tipoArchivo=$(file -b --mime-type "$2")
    if [ $tipoArchivo != "text/plain" ]
    then
        echo "Error, se debe pasar archivo de texto por parametro"
        exit 1
    fi
}

cantidadCorreciones(){
    espaciosDuplicados=$(grep -E -o "[ ]{2,}" "$1" | wc -l)
    espaciosSignos=$(grep -E -o " [.;,]" "$1" | wc -l)
    noEspaciosSignos=$(grep -E -o "[.;,][^ ]" "$1" | wc -l)

    return $(($espaciosDuplicados+$espaciosSignos+$noEspaciosSignos))
}

realizarReemplazos(){
    sed 's/[ ]\{2,\}/ /g; ; s/\s\+\([,;.]\)/\1/g ; s/\([.;,]\)\(\w\)/\1 \2/g' "$1" > "$2"
}

modulo()
{
    numero=$1
    if [ $numero -lt 0 ]
    then
        ((numero*=-1))
    fi
    return $numero
}

contarInconsistencias(){
    parentesis=$(( $(grep -o -e "(" "$1" | wc -l) - $(grep -o -e ")" "$1" | wc -l) ))
    modulo $parentesis
    parentesis=$?

    preguntas=$(( $(grep -o -e "¿" "$1" | wc -l) - $(grep -o -e "\?" "$1" | wc -l) ))
    modulo $preguntas
    preguntas=$?

    signosAdmiracion=$(( $(grep -o -e "¡" "$1" | wc -l) - $(grep -o -e "\!" "$1" | wc -l) ))
    modulo $signosAdmiracion
    signosAdmiracion=$?
}

imprimirArchivoLog(){
    echo "La cantidad de correciones realizadas fueron: $2." > "$1"
    echo "La cantidad de parentesis dispares es: $3." >> "$1"
    echo "La cantidad de signos de pregunta dispares es: $4." >> "$1"
    echo "La cantidad de signos de exclamacion dispares es: $5." >> "$1"
}

mostrarAyuda $1

if [[ $# > 2 ]]
then
    echo "Error, se pasaron mas parametros de los permitidos"
    exit 1
fi

validarParametros $1 "$2"

pathCompleto=""
pathLog=""
generarNombresArchivos "$2" 

cantidadCorreciones "$2"
cantidadCorreciones=$?

realizarReemplazos "$2" "$pathCompleto"

contarInconsistencias "$2"

imprimirArchivoLog "$pathLog" $cantidadCorreciones $parentesis $preguntas $signosAdmiracion
