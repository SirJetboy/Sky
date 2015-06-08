#!/bin/bash
#sudo apt-get install git
#git clone https://github.com/Snowv/Sky.git
#git add rvsh.sh 
#git commit -m "Description du commit"
#git log -p HEAD..FETCH_HEAD
#git remote add bob https://github.com/Snowa/Sky-1.git
#git fetch bob
#git fetch bob
#git merge bob/master
#git pull alice master
#git push bob master

#Exemple pour Rob' 
# ./rvsh.sh -admin #Lance programme en mode administrateur
#Tu peux utiliser les commandes host, users, clear, afinger
#exemple: 
#host create pc5
#host remove pc6
#users add pc5 jojo aaa #ajoute l'utilisateur jojo à la machine pc5 avec le mdp aaa
#users remove pc5 jojo  #supprime l'acces à l'utilisateur jojo sur le pc5
#afinger jojo #commande pour ajouter une desciption à l'utilisateur jojo
#clear #similaire au clear de linux
#./rvsh.sh -connect jojo pc1 #lance le programme en mode utilisateur 

#mot de passe
#commande su

Red='\033[1;31m'

programname=$0
access=access
utilisateurCourant=""
machineCourante=""

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
echo "apture du Signal CTRL+C"
# modification : suppression du "!" avant "-z"
if [[ -z utilisateurCourant && -z machineCourante ]]; then
	#utilisateurCourant=""
	#       machineCourante=""
	echo "Déconnexion !"
	sed -i "/$utilisateurCourant $machineCourante/d" status
fi
exit $?
}

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


# Mode connect

function connect {
MACHINECOURANTE=$2
utilisateurCourant=$1
while [[ true ]]; do
	echo -e "${Red}$1@$2> \c"
	machineCourante=$2
	utilisateurCourant=$1
	if [[ -z $(grep "$1 $2" status) ]]; then
		renseignerConnexion $1 $2
	fi
	tput sgr0 #  Réinitialise les couleurs à la normale.
	read line

	cmd=$(echo $line | cut -f1 -d" ")
	case $cmd in
		rhost )
			rhost
			;;
		finger )
			finger $1
			;;
		su )
			userName=$(echo $line | cut -f2 -d" ")
			su $userName $2 $1
			;;
		test )
			ftest
			;;
		who )
			who $1 $2
			;;
		clear )
			clear
			;;
		exit )
			renseignerDeconnexion $utilisateurCourant $machineCourante
			machineCourante=$2
			utilisateurCourant=$1
			break
			;;
		passwd )
			userName=$
			passwd $1
			;;
		write )
			destinataireMachine=$(echo $line | cut -f2 -d" ")
			write "$destinataireMachine" "$line"
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

function who {
while read ligne  
do  
	user=$(echo $ligne | cut -f1 -d" ")
	machine=$(echo $ligne | cut -f2 -d" ")
	if [[ $1 = $user && $2 = $machine ]]; then
		echo $ligne | cut -f1,3-7 -d" "
	fi  
done < status
}

function rhost {
echo -e "\nListe des machines connectées : "
liste=""
for i in $(ls); do
	if [[ -d $i && $i != "access" ]]; then
		liste="$liste $i"
	fi
done
echo -e "\n$liste"
}

function su {
if [[ ! -z $(grep $2 access/$1) ]]; then
	retourGrep=$(grep "$1" .shadow)
	if [[ ! -z $retourGrep ]]; then
		password=$(echo $retourGrep | cut -f2 -d':')
		read -s -p "Entrez le mot de passe : " motDePasse
		if [[ $motDePasse = $password ]]; then
			echo "SUCCESS"
			renseignerDeconnexion $3 $2
			renseignerConnexion $1 $2
			connect $1 $2
		else
			echo "FAILURE"
		fi
	fi
else
	echo "Vous ne pouvez pas vous authentifier sur cette machine !"
fi
}

function passwd {
echo "Modification de votre mot de passe."
retourGrep=$(grep $1 .shadow)
password=$(echo $retourGrep | cut -f2 -d':')
read -s -p "Entrez votre mot de passe actuel : " motDePasse
motDePasse=$(echo $motDePasse | md5sum | cut -b1-32)
if [[ $motDePasse = $password ]]; then
	echo "SUCCESS"	
	read -s -p "Tapez votre nouveau mot de passe : " passwd1
	passwd1=$(echo $passwd1 | md5sum | cut -b1-32)
	echo ""
	read -s -p "Tapez une seconde fois votre mot de passe : " passwd2
	passwd2=$(echo $passwd2 | md5sum | cut -b1-32)
	if [[ $passwd1 = $passwd2 ]]; then
		lineNumber=$(grep -n $1 .shadow | cut -f1 -d':')
		if [ ! -z $lineNumber ]; then
			d="d"
			sed -i -e "$lineNumber$d" .shadow >> /dev/null
			echo "$1:$passwd1" >> .shadow
			echo "SUCCESS"
		else
			echo "FAILURE"
		fi
	else
		echo "FAILURE"
	fi
else
	echo "FAILURE"
fi
}

function finger {
grep $1 infoUtilisateurs.txt | cut -f2 -d':'
}

function write {
message=$(echo $2 | awk '{for (i=3;i<=NF;i++) printf $i" ";}')
destinataire=$(echo $1 | cut -d"@" -f1)
machine=$(echo $1 | cut -d"@" -f2)
terminal=$(grep "$destinataire $machine" status | head -n 1 | cut -d" " -f8)
if [[ -z $terminal ]]; then
	echo "Cet utilisateur n'est pas connecté !"
else
	echo $message | /usr/bin/write $USER $terminal 
fi
}

function renseignerConnexion {
date=$(date | cut -f1 -d',')
heure=$(date | cut -f5 -d' ')
echo $1 $2 $date $heure $(tty) >> status 
}

function renseignerDeconnexion {
lineNumber=$(grep -n "$1 $2" status | cut -f1 -d':')
if [[ ! -z $lineNumber ]]; then
	d="d"
	sed -i -e "$lineNumber$d" status
fi
}


# Mode admin

function admin {
echo "Mode admin"
while [[ true ]]; do
	echo -e "${Red}>rvsh \c"
	tput sgr0 #  Réinitialise les couleurs à la normale."
	read line
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
		clear )
			clear
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
		exit )
			break
			;;
		passwd )
			passwdadmin
			;;
		* )
			echo "Commande inconnue"
			;;
	esac
done
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

function users { # $action $machineName $userName  $password
echo "Commande administrateur users "
if [[ $(echo $* | wc -w) = 4 && $1 == "add" ]]; then
	addUser $3 $2 $4 
elif [[ $(echo $* | wc -w) = 3 && $1 == "remove" ]]; then
	removeUser $3 $2
else
	usage_users
fi
}

function addUser {
motDePasse=$(echo $3 | md5sum | cut -b1-32)
if [[ ! -d $access ]]; then
	mkdir $access
fi 
if [[ ! -z $1 && ! -z $2 && ! -z $motDePasse  ]]; then #test si la chaine est non vide
	if [[ -d $2 ]]; then
		if [[ -f $access/$1 ]]; then
			grep -q "$2" $access/$1
		fi
		if [[ ! -f $access/$1 || $? -ne 0 ]]; then
			echo "$2" >> $access/$1
			if [[ ! -f .shadow || $(grep $1 .shadow | wc -l) -eq 0 ]]; then
				echo "$1:$motDePasse" >> .shadow
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
			echo "Utilisateur $1 ajouté à la machine $2"
		else
			echo "Utilisateur et machine déjà renseigné !"
		fi
	else
		echo "La machine $2 n'est pas encore créée"
	fi
else 
	echo "Une valeur n'est pas renseigné !"
fi
}

function removeUser {
if [[ ! -z $1 && ! -z $2 ]]; then #test si la chaine est non vide
	if [[ -d $2 && -e $access/$1 ]]; then
		lineNumber=$(grep -n "$2" $access/$1 | cut -f1 -d':')
		if [ ! -z $lineNumber ]; then
			d="d"
			sed -i -e "$lineNumber$d" $access/$1
			if [[ ! -s $access/$1  ]]; then
				rm $access/$1
			fi
			echo "Accès de l'utilisateur $1 supprimé de la machine $2"
		else
			echo "L'utilisateur n'est pas associé à cette machine"
		fi
	else
		echo "La machine $2 n'est pas encore créée ou il n'y a pas encore d'utilisateur autorisé à l'utiliser"
	fi
else 
	echo "Une valeur n'est pas renseigné !"
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

function ajouterDescription { 
read -p "Entrez la description: " description
echo $1 $description
ligne=$(grep -n ^$1: infoUtilisateurs.txt | cut -f1 -d':')
d="d"
cmd=$ligne$d
sed -i -e "$cmd" infoUtilisateurs.txt
echo "$1:$description" >> infoUtilisateurs.txt
}

function passwdadmin {
echo "Modification du mot de passe pour le mode admin."
retourGrep=$(grep admin .shadow)
password=$(echo $retourGrep | cut -f2 -d':')
read -s -p "Entrez le mot de passe du mode admin : " motDePasse
motDePasse=$(echo $motDePasse | md5sum | cut -b1-32)
if [[ $motDePasse = $password ]]; then
	echo "SUCCESS"	
	read -s -p "Tapez le nouveau mot de passe : " passwd1
	passwd1=$(echo $passwd1 | md5sum | cut -b1-32)
	echo ""
	read -s -p "Tapez une seconde fois le mot de passe : " passwd2
	passwd2=$(echo $passwd2 | md5sum | cut -b1-32)	
	if [[ $passwd1 = $passwd2 ]]; then
		lineNumber=$(grep -n admin .shadow | cut -f1 -d':')
		if [ ! -z $lineNumber ]; then
			d="d"
			sed -i -e "$lineNumber$d" .shadow >> /dev/null
			echo "admin:$passwd1" >> .shadow
			echo "SUCCESS"
		else
			echo "Une erreur s'est produite lors de la modification du mot de passe."
		fi
	else
		echo "FAILURE"
	fi
else
	echo "FAILURE"
fi


}

{
if [[ ! -z $1 && $1 == "-admin" ]]; then
	if [[ ! -f .shadow ]]; then 
		mdp=$(echo "admin" | md5sum | cut -b1-32)
		echo admin:$mdp > .shadow
	fi
	if [[ $(echo $* | wc -w) = 1 ]]; then
			retourGrep=$(grep admin .shadow)
			password=$(echo $retourGrep | cut -f2 -d':')
			read -s -p "Entrez le mot de passe du mode admin : " motDePasse
			motDePasse=$(echo $motDePasse | md5sum | cut -b1-32)
				if [[ $motDePasse = $password ]]; then
					echo "SUCCESS"
					admin
				else
					echo "FAILURE"
				fi
	#else
		#usage
	fi
elif [[ ! -z $1 && $1 == "-connect" ]]; then
	if [[ $(echo $* | wc -w) = 3 && -d $2 ]]; then
		if [[ -e "access/$3" && ! -z $(grep $2 access/$3) ]]; then
			retourGrep=$(grep $3 .shadow)
			if [[ ! -z $retourGrep ]]; then
				password=$(echo $retourGrep | cut -f2 -d':')
				read -s -p "Entrez votre mot de passe : " motDePasse
				motDePasse=$(echo $motDePasse | md5sum | cut -b1-32)
				if [[ $motDePasse = $password ]]; then
					echo "SUCCESS"
					renseignerConnexion $3 $2
					connect $3 $2
				else
					echo "FAILURE"
				fi
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
}
