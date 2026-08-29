<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>¡Infraestructura Gestionada con Ansible Exitosamente!</h1>";

$mysqli = new mysqli("10.0.20.10", "web_user", "PasswordSegura123", "lab_devops");

if ($mysqli->connect_error) {
    echo "<p>Error de conexión a la DB: " . $mysqli->connect_error . "</p>";
} else {
    echo "<p>Conexión a la DB centralizada: <b>EXITOSA</b></p>";
    echo "<p>Hora del clúster: " . date("H:i:s") . "</p>";
}
?>
