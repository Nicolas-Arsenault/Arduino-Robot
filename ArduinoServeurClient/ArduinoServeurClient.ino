/*************************************************************************************************************************
* Nom du fichier : TP3ardu.ino                                                                                           *
* Auteur : Nicolas Arsenault                                                                                             *
* Date De dernière modification : 2024-05-02                                                                             *
* Description du programme : Serveur pour un robot arduino qui sera connecté WiFi et envoiera la température et le taux  *
* d'humidité via un DHT11 aux clients connectés. Il lit aussi les données d'un serveur qui lui envoie les directions pour* 
* le controler et envoie celles-ci à un serveur Processing.                                                              *
 ************************************************************************************************************************/
#include <DHT.h>
#include <WiFiNINA.h> 

//déclarer serveur sur le port 5000...
//"client" sera utilisé pour le client processing au serveur arduino et "client2" sera utilisé pour le client arduino au serveur processing
WiFiServer serveur(5000);  WiFiClient client; WiFiClient client2; 

//les broches pour les moteurs et leurs vitesses
#define BROCHE_DIRECTION_M1M3 4
#define BROCHE_VITESSE_M1M3 5
#define BROCHE_VITESSE_M2M4 6
#define BROCHE_DIRECTION_M2M4 7              

#define DHTPIN 2 //le dht11 est sur la pin digital 2...
#define DHTTYPE DHT11 //Définir DHT11 du type DHTTYPE 

DHT dht(DHTPIN, DHTTYPE); //variable dht sera de type DHT et sur la pin 2, de type dht11...

String tempEtHumidite = "";
long tempsAuDebutDuNouveauDelai = 0;

/*******************
* Fonction setup() *
*******************/
void setup() 
{
  int noBroche;
  
  Serial.begin(9600);
  dht.begin();

  //définir les broches à output, pour les moteurs
  for (noBroche = 4; noBroche <= 7; noBroche++)
  {
    pinMode(noBroche, OUTPUT); 
  }

  pinMode(9, OUTPUT); //LED indiquante si on est connecté au wifi ou non
  pinMode(8, OUTPUT); //LED indiquant la connexion au serveur processing
  
  connexionWiFi(); //se connecter au routeur sans fil.
  connexionLogicielServeur(); //se connecter au serveur processing.
}

/*******************
* Fonction loop()  *
*******************/
void loop() 
{
  byte robotDirection; //recevera le mouvement (sa direction)que le robot executera...

  //si on est pas connecté au WiFi, éteindre la LED, sinon, l'allumer...
  if(WiFi.status() != WL_CONNECTED)
  {
    digitalWrite(9, LOW);
    connexionWiFi();
  }
  else
  {
    digitalWrite(9, HIGH);
  }

  //vérifier si le robot est connecté au client processing
  if(!client2.connected())
  {
    digitalWrite(8, LOW);
   
    connexionLogicielServeur();
  }

  //envoie la température et l'humidité capté sur le DHT11 toutes les 1 secondes...
  delaiEtEnvoieTempHumidite(1000);
  
  client = serveur.available(); //vérifier si l'on reçoit des données du serveur processing...

 //Si oui, la lire et faire bouger le robot en fonction de la direction envoyé
  if(client) 
  {
    robotDirection = client.read();
    
    switch(robotDirection)
    {
      case 1 : 
      //avancer
        digitalWrite(BROCHE_DIRECTION_M1M3, HIGH);
        analogWrite(BROCHE_VITESSE_M1M3, 255);
        digitalWrite(BROCHE_DIRECTION_M2M4, LOW);
        analogWrite(BROCHE_VITESSE_M2M4, 255);
        envoyerDonnee(1);//envoyer le mouvement et les infos complémentaires au serveur processing
        break;
        
      case 0 : 
      //arreter
        digitalWrite(BROCHE_VITESSE_M1M3, LOW);
        digitalWrite(BROCHE_VITESSE_M2M4, LOW);
        envoyerDonnee(0);//envoyer le mouvement et les infos complémentaires au serveur processing
        break;
        
      case 2 : 
      //reculer
        digitalWrite(BROCHE_DIRECTION_M1M3, LOW);
        analogWrite(BROCHE_VITESSE_M1M3, 255);
        digitalWrite(BROCHE_DIRECTION_M2M4, HIGH);
        analogWrite(BROCHE_VITESSE_M2M4, 255);
        envoyerDonnee(2);//envoyer le mouvement et les infos complémentaires au serveur processing
        break;

      case 3 : 
      //pivoter sur la gauche
        digitalWrite(BROCHE_DIRECTION_M1M3, HIGH);
        analogWrite(BROCHE_VITESSE_M1M3, 255);
        digitalWrite(BROCHE_DIRECTION_M2M4, HIGH);
        analogWrite(BROCHE_VITESSE_M2M4, 255);
        envoyerDonnee(3);//envoyer le mouvement et les infos complémentaires au serveur processing
        break;

      case 4:
       //pivoter sur la droite
        digitalWrite(BROCHE_DIRECTION_M1M3, LOW);
        analogWrite(BROCHE_VITESSE_M1M3, 255);
        digitalWrite(BROCHE_DIRECTION_M2M4, LOW);
        analogWrite(BROCHE_VITESSE_M2M4, 255);
        envoyerDonnee(4);//envoyer le mouvement et les infos complémentaires au serveur processing
        break;
    }
  }
}

/****************************
* Fonction connexionWiFi()  *
****************************/
void connexionWiFi() 
{
  //SSID et mdp du routeur sans fil...
  char ssid[] = "h212"; 
  char motDePasse[] = "cisco1234"; 

  //configuration réseau de la carte Arduino WiFi...
  IPAddress ipStatique(192, 168, 1, 151);
  IPAddress masqueStatique(255, 255, 255, 0);
  IPAddress passerelleStatique(192, 168, 1, 1);
  IPAddress dnsStatique(1, 1, 1, 1); 

  //Se connecter au routeur
  WiFi.begin(ssid, motDePasse);

  //Appliquer la configuration réseau...
  WiFi.config(ipStatique, dnsStatique, passerelleStatique, masqueStatique);

  digitalWrite(9, HIGH);

  //démarrer le serveur
  serveur.begin();
}

/****************************************
* Fonction delaiEtEnvoieTempHumidite()  *
****************************************/
void delaiEtEnvoieTempHumidite(int delai)
{
  long tempsActuel;

  tempsActuel = millis(); //temps actuel en milisecondes

  //Si le délai de 1 seconde est dépassé, enregistrer le nouveau début du délai et faire le calcul de l'humidité et température. L'envoyer au client processing ensuite.
  if(tempsActuel > tempsAuDebutDuNouveauDelai + delai)
  {
    int humidite;
    float temperature ;
    String temperatureArrondi;
    tempEtHumidite = "";

    temperature =  dht.readTemperature(); //lire la temperature sur le dht11
    temperatureArrondi = (String)temperature; //la convertire en type "String"
    temperatureArrondi = temperatureArrondi.substring(0, temperatureArrondi.length() - 1); //effacer la deuxième décimale de temperatureArrondi (ex: 23,08 -> 23,0)
        
    humidite =  dht.readHumidity(); //lire l'humidité sur le dht11

    tempEtHumidite = temperatureArrondi + (String)humidite + "f"; //préparer la chaîne à envoyer sous format TT.THHf. "f" indiquera la fin de la chaîne...
    serveur.print(tempEtHumidite);  //envoyer cette chaîne de caractère

    tempsAuDebutDuNouveauDelai = tempsActuel; //sauvegarder le nouveau début du délai.
  }
}

/****************************
* Fonction envoyerDonnee()  *
****************************/
void envoyerDonnee(int mouvement)
{
  int indice;
  String donneesPourAccess = "";
  String ipClientProcessing = "";
  String iPRobot = "";

  //prendre l'adresse ip de la machine locale (Robot) et du client qui est connecté, et le mettre dans une chaîne..
  for(indice = 0; indice <= 3; indice ++)
  {
    iPRobot = iPRobot  + (String)WiFi.localIP()[indice]+ "."; //concatenation qui donnera un résultat similaire: "192.168.1.1."
    ipClientProcessing = ipClientProcessing + (String)client.remoteIP()[indice]+ "."; //même chose mais pour l'IP du client...
  }
  
  //retirer le "." à la fin avec un substring...
  iPRobot = iPRobot.substring(0, iPRobot.length() - 1) + "f";
  ipClientProcessing = ipClientProcessing.substring(0, ipClientProcessing.length() - 1) + "f";

  //mettre le tout dans une chaine de format X.X.X.XfX.X.X.XfM.
  donneesPourAccess = iPRobot + ipClientProcessing + (String) mouvement;

  //L'envoyer au serveur processing qui est défini par la connection au client 2
  client2.print(donneesPourAccess);
  
}

/*************************************
* Fonction connexionLogicielServeur  *
*************************************/
void connexionLogicielServeur()
{
  //essayer de se connecter au serveur processing, et tant qu'il ne l'est pas, réessayer après 5 secondes.
  while(!client2.connect("10.10.212.26", 5000))
  {
    delay(5000);
  }

  //après avoir réussi la connection, allumer la LED à la pin 8.
  digitalWrite(8, HIGH);
}
