// Data sementara
// nanti diganti API database


const reportData = {


income:0,

order:0,

newUser:0,

driver:0


};





document.getElementById("totalIncome").innerHTML =
"Rp" + reportData.income;



document.getElementById("totalReportOrder").innerHTML =
reportData.order;



document.getElementById("newUser").innerHTML =
reportData.newUser;



document.getElementById("activeDriver").innerHTML =
reportData.driver;









// Chart Pendapatan


new Chart(
document.getElementById("incomeChart"),

{


type:"line",


data:{


labels:[
"Jan",
"Feb",
"Mar",
"Apr",
"Mei",
"Jun",
"Jul"
],


datasets:[{


label:"Pendapatan",

data:[
0,0,0,0,0,0,0
],

fill:true,

tension:.4,

borderWidth:3


}]


},



options:{


responsive:true,

maintainAspectRatio:false


}



}

);










// Chart Order


new Chart(

document.getElementById("orderChart"),

{


type:"bar",


data:{


labels:[
"Jan",
"Feb",
"Mar",
"Apr",
"Mei",
"Jun",
"Jul"
],


datasets:[{


label:"Jumlah Order",


data:[
0,0,0,0,0,0,0
],


borderRadius:10


}]


},



options:{


responsive:true,

maintainAspectRatio:false


}


}

);