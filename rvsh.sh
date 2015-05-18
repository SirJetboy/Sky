#!/bin/bash
#sudo apt-get install git
#git clone https://github.com/Snowv/Sky.git
#git add rvsh.sh 
#git commit -m "Description du commit"
#git log -p HEAD..FETCH_HEAD
#git remote add bob https://github.com/Snowa/Sky-1.git
#git fetch bob
#git merge bob/master
#git pull alice master
#git push bob master

programname=$0
acess=acess

function usage {
    echo "usage: $programname [-option] [nom_machine] [nom_utlisateur]"
    echo "  -connect    Le mode connect permet à un utilisateur de se connecter à une machine virtuelle"
    echo "  -admin      Cette commande permet à l’administrateur de gérer la liste des machines connectées au réseau virtuel"
    echo "              et la liste des utilisateurs. Lorsque que la commande admin est saisi il n'y a pas besoin de saisir le nom d'utilisateur"
    echo "              et le nom de la machine"
    echo "  -help       affiche de l'aide"
    exit 1
}
function usage_host {
    echo "usage: >rvsh host [create|remove] [nom_machine] "
    echo "  -connect    Le mode connect permet à un utilisateur de se connecter à une machine virtuelle"
    echo "  -admin      Cette commande permet à l’administrateur de gérer la liste des machines connectées au réseau virtuel"
    echo "              et la liste des utilisateurs. Lorsque que la commande admin est saisi il n'y a pas besoin de saisir le nom d'utilisateur"
    echo "              et le nom de la machine"
    echo "  -help       affiche de l'aide"
}
function usage_users {
    echo "usage: >rvsh host [create|remove] [nom_machine] "
    echo "  -connect    Le mode connect permet à un utilisateur de se connecter à une machine virtuelle"
    echo "  -admin      Cette commande permet à l’administrateur de gérer la liste des machines connectées au réseau virtuel"
    echo "              et la liste des utilisateurs. Lorsque que la commande admin est saisi il n'y a pas besoin de saisir le nom d'utilisateur"
    echo "              et le nom de la machine"
    echo "  -help       affiche de l'aide"
}
function users { # $action $userName $machineName $password
echo "Commande administrateur users "
if [[ $(echo $* | wc -w) = 4 && $1 == "add" ]]; then
    addUser $2 $3 $4 
elif [[ $(echo $* | wc -w) = 3 && $1 == "remove" ]]; then
    removeUser $2 $3
else
    usage_users
fi
}
function ftest {
    fichier=infoUtilisateurs.txt
    path=$(pwd)
    nomComplet=$path/$fichier
    echo $t
    if [ -f $nomComplet ]; then
        echo "Le fichier existe"
    else
        echo "Le fichier n'existe pas"
        echo $(pwd)
    fi
}

function addUser {
if [[ ! -d $acess ]]; then
     mkdir $acess
 fi 
    if [[ ! -z $1 && ! -z $2 && ! -z $3  ]]; then #test si la chaine est non vide
        if [[ -d $2 ]]; then
            if [[ -f $acess/$1 ]]; then
                grep -q "$2" $acess/$1
            fi
            if [[ ! -f $acess/$1 || $? -ne 0 ]]; then
                echo "$2" >> $acess/$1
                if [[ ! -f shadow || $(grep $1 shadow | wc -l) -eq 0 ]]; then
                    echo "$1:$3" >> shadow
                fi
                if [ -e infoUtilisateurs.txt ]; then
                    if [[ $(grep $1 infoUtilisateurs.txt | wc -l) -ne 1 ]]; then
                        pointv=":"
                        echo "$1$pointv" >> infoUtilisateurs.txt
                    fi
                else
                    pointv=":"
                    echo "$1$pointv" >> infoUtilisateurs.txt
                    
                fi
                echo "Utilisateur $1 ajouté à la machine $2 avec le mdp $3"
            else
                echo "Utilisateur et machine déjà renseigné !"
            fi
        else
            echo "La machine $2 n'est pas encore créer"
        fi
    else 
        echo "Une valeur n'est pas renseigné !"
    fi
}
function removeUser {
    if [[ ! -z $1 && ! -z $2 ]]; then #test si la chaine est non vide
        if [[ -d $2 && -e $acess/$1 ]]; then
            lineNumber=$(grep -n "$2" $acess/$1 | cut -f1 -d':')
            if [ ! -z $lineNumber ]; then
                d="d"
                sed -i -e "$lineNumber$d" $acess/$1
                if [[ ! -s $acess/$1  ]]; then
                    rm $acess/$1
                fi
            echo "Accès de l'utilisateur $1 supprimé de la machine $2"
        else
            echo "L'utilisateur n'est pas associé à cette machine"
        fi
    else
        echo "La machine $2 n'est pas encore créer ou il n'y a pas encore d'utilisateur autorisé à l'utiliser"
    fi
else 
    echo "Une valeur n'est pas renseigné !"
fi
}
function admin {
    echo "Commande administrateur"
    while [[ true ]]; do
        read -p ">rvsh " line
        cmd=$(echo $line | cut -f1 -d" ")
        case $cmd in
            host )
action=$(echo $line | cut -f2 -d" ")
machineName=$(echo $line | cut -f3 -d" ")
host $action $machineName ;;
afinger )
userName=$(echo $line | cut -f2 -d" ")
afinger $userName
;;
test )
ftest
;;
users )
action=$(echo $line | cut -f2 -d" ")
userName=$(echo $line | cut -f3 -d" ")
machineName=$(echo $line | cut -f4 -d" ")
password=$(echo $line | cut -f5 -d" ")
users $action $userName $machineName $password
;;
"" ) #Juste pour un meilleur effet visuel
;;
* )
echo "Commande inconnue"
;;
esac
done
}

function ajouterDescription { 
read -p "Entrez la description: " description
echo $1 $description
ligne=$(grep -n ^$1: infoUtilisateurs.txt | cut -f1 -d':')
d="d"
cmd=$ligne$d
sed -i -e "$cmd" infoUtilisateurs.txt
echo "$1:$description" >> infoUtilisateurs.txt
}
function host {
    echo $*
    if [[ $(echo $* | wc -w) = 2 && $1 == "create" ]]; then
        createVirtualMachine $2
    elif [[ $(echo $* | wc -w) = 2 && $1 == "remove" ]]; then
        removeVirtualMachine $2
    else
        usage_host
    fi
}
function afinger {
    compteur=1
    if [[ -f infoUtilisateurs.txt ]]; then 
        echo "Liste des utilisateurs du réseaux + Description :"
        for ligne in $(cat infoUtilisateurs.txt) ; do
            user=$(echo $ligne | cut -f1 -d":")
            desciprion=$(echo $ligne | cut -f2 -d":")
            echo -e "Utilisateur: $user\tDesciption:\t$desciprion"
            compteur=$(expr $compteur + 1)
        done
        nbLigne=$(grep $1: infoUtilisateurs.txt | wc -l)
        user=$(echo $ligne | cut -f1 -d":")
        if [[ $nbLigne -eq 1 ]]; then
            if [[ $(echo $* | wc -w) = 1 ]]; then
                ajouterDescription $1
            fi
        else
            echo "L'utilisateur $1 est inconnu"
        fi
    else
        echo "Vous n'avez pas encore ajouté des utilisateurs à votre réseau !"
    fi

}
function createVirtualMachine {
    if [ ! -z $1  ]; then #test si la chaine est non vide
        if [  ! -d  $1 ]; then
            mkdir $machineName 
            echo "Machine $1 créée"
        else
            echo "La machine virtuel est déjà créée"
        fi
    else 
        echo "Nom de machine incorrect"
    fi
}
function removeVirtualMachine {
    if [ ! -z $1  ]; then #test si la chaine est non vide
        if [ -d  $1 ]; then
            rm -Rf $1 
            echo "Machine $1 supprimée"
        else
            echo "La machine virtuel n'est pas encore créée"
        fi
    else 
        echo "Nom de machine incorrect"
    fi
}
function rhost {
    echo "Liste des machines connectées : "
    liste=""
    for i in $(ls); do
        if [[ -d $i ]]; then
            liste="$liste $i"
        fi
    done
    echo $liste
}
function finger {
    grep "juju" infoUtilisateurs.txt | cut -f2 -d':'
}
function passwd {
    echo "Changing password for $1 ."
    read -s -p "Tapez votre nouveau mot de passe " passwd1
    read -s -p "Tapez une seconde fois votre mot de passe " passwd2
    if [[ $passwd1 = $passwd2 ]]; then
        grep -n "$1" shadow
        lineNumber=$(grep -n "$1" shadow | cut -f1 -d':')
        if [ ! -z $lineNumber ]; then
            d="d"
            sed -i -e "$lineNumber$d" shadow
            echo "$1:$passwd1" >> shadow
        else
            echo "erreur"
        fi
    fi
}
function modeConnect {
  while [[ true ]]; do
    read -p "$1@$2> " line
    cmd=$(echo $line | cut -f1 -d" ")
    case $cmd in
        rhost )
rhost
;;
finger )
finger 
;;
test )
ftest
;;
passwd )
userName=$
passwd $1
;;
users )
action=$(echo $line | cut -f2 -d" ")
userName=$(echo $line | cut -f3 -d" ")
machineName=$(echo $line | cut -f4 -d" ")
password=$(echo $line | cut -f5 -d" ")
users $action $userName $machineName $password
;;
"" ) #Juste pour un meilleur effet visuel
;;
* )
echo "Commande inconnue"
;;
esac
done
}
if [[ ! -z $1 && $1 == "-admin" ]]; then
    admin
elif [[ ! -z $1 && $1 == "-connect" ]]; then
    if [[ $(echo $* | wc -w) = 3 && -d $3 ]]; then
        retourGrep=$(grep $2 shadow)
        if [[ ! -z $retourGrep ]]; then
            password=$(echo $retourGrep | cut -f2 -d':')
            read -s -p "Entrez votre mot de passe : " motDePasse
            if [[ $motDePasse = $password ]]; then
                echo "SUCESS"
                modeConnect $2 $3
            else
                echo "Mot de passe incorrect"
            fi
        else
            echo "Utilisateur inconnu ou machine inconnu"
        fi
    else
        usage
    fi
else
    usage
fi
