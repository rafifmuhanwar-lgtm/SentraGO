// Data sementara driver
// nanti diganti API Database


const driverData = {


    total:0,

    online:0,

    busy:0,

    offline:0


};




// Update Statistik


document.getElementById("totalDriver").innerHTML =
driverData.total;



document.getElementById("driverOnline").innerHTML =
driverData.online;



document.getElementById("driverBusy").innerHTML =
driverData.busy;



document.getElementById("driverOffline").innerHTML =
driverData.offline;



document.getElementById("driverCount").innerHTML =
driverData.total + " Data";