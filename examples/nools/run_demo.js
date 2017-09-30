var nools = require("nools")


function Person(name, height) {
    this.name = name
    this.height = height
}

function Car(owner) {
    this.owner = owner
}

var options = {
    name: "DRAKON-nools demo",
    define: {
        Person: Person,
        Car: Car
    }
}

var flow = nools.compile("nools_demo.nools", options)


var session = flow.getSession()
session.assert(new Person("Jan", 170))
session.assert(new Person("Jan", 190))
var jan = new Person("Jan", 175)
session.assert(jan)
session.assert(new Person("Jon", 190))
session.assert(new Car(jan))

session.match()