
#%%
# let's learn object-oriented programming (OOP) in Python!

# In OOP, we create classes that define the blueprint for objects.
# Each object is an instance of a class and can have attributes (data) and methods (functions) that operate on that data.
# __init__ stands for a constructor method that initializes the object's attributes when an instance of the class is created.
# an object is an instance of a class, and it can have its own unique values for the attributes defined in the class.
# a class can also have methods, which are functions that define the behavior of the objects created from the class.

# A dunder method is a special method in Python that starts and ends with double underscores (e.g., __init__). 
# These methods have special meanings and are used to define the behavior of objects in certain situations.

#
# from car import Car

class Car:
    def __init__(self, model, year, color, for_sale):
        # Instance attributes (unique to each car)
        self.model = model
        self.year = year
        self.color = color
        self.for_sale = for_sale

    # Method (behavior)
    def drive(self):
        print(f"You drive the {self.model}")

    def stop(self):
        print(f"You stop the {self.model}")

    def describe(self):
        print(f"This is a {self.color} {self.year} {self.model}.")

car1 = Car("Mustang", 2024, "red", False)
car2 = Car("Corvette", 2025, "blue", True)

# Check how the attribute access operator (.) is used to access the attributes of the car1 object
print(car1.model)
print(car1.year)
print(car1.color)
print(car1.for_sale)
print(car2.model)
print(car2.year)
print(car2.color)
print(car2.for_sale)


car1.drive()
car1.stop()

car1.describe()

#######################################################

# Methods are actions that can be performed on objects. 
# They are defined within a class and can operate on the attributes of the object. 

# Class variables are shared among all instances of a class, 
# while instance variables are unique to each instance.
# Will be defined outside of the constructor

class Student:

    class_year = 2026 # this is the class variable, shared among all instances of the Student class 
    num_students = 0
    def __init__(self, name, age):
        self.name = name
        self.age = age
        Student.num_students += 1 # increment the class variable num_students 
                                  # by 1 each time a new instance is created

student1 = Student("Spongebob", 30)
student2 = Student("Patrick", 35)

print(student1.name)
print(student1.age)
print(student1.class_year)
print(Student.class_year) # this is the best practice to access class variables using the class name
print(Student.num_students)

student3 = Student("Squidward", 55)
print(Student.num_students)

print(f"My graduating class of {Student.class_year} has {Student.num_students} students.")



#######################################################

# Inheritance is a way to create a new class (child class) that is based on an existing class (parent class).
# The child class inherits the attributes and methods of the parent class,
# and can also have its own unique attributes and methods.

class Animal:
    def __init__(self, name):
        self.name = name
        self.is_alive = True

    def eat(self):
        print(f"{self.name} is eating")

    def sleep(self):
        print(f"{self.name} is sleeping")

class Dog(Animal): # Dog is the child class that inherits from the Animal class
    def speak(self):
        print("WOOF")

class Cat(Animal):
    def speak(self):
        print("MEOW")

class Mouse(Animal):
    pass

dog = Dog("Scooby")
cat = Cat("Garfield")
mouse = Mouse("Mickey")

print(dog.name)
print(dog.is_alive)
dog.eat()
dog.sleep()

dog.speak()
cat.speak()

#######################################################

# multiple inheritance is a feature in object-oriented programming where
#  a class can inherit attributes and methods from more than one parent class.

# multilevel inheritance is a feature in object-oriented programming where
# a class can inherit attributes and methods from a parent class, which in
#  turn inherits from another parent class, creating a chain of inheritance.

# grandparent
class Animal:
    def __init__(self, name):
        self.name = name

    def eat(self):
        print(f"{self.name} is eating")

    def sleep(self):
        print(f"{self.name} is sleeping")

# parent
class Prey(Animal):
    def flee(self):
        print(f"{self.name} is fleeing")

# parent
class Predator(Animal):
    def hunt(self):
        print(f"{self.name} is hunting")

# child
class Rabbit(Prey):
    pass

#child
class Hawk(Predator):
    pass

#child - multiple inheritance
class Fish(Prey, Predator):
    pass

rabbit = Rabbit("Bugs")
hawk = Hawk("Tony")
fish = Fish("Nemo")

rabbit.flee()
hawk.hunt()
fish.flee()
fish.hunt()

rabbit.eat()
fish.sleep()


#######################################################

# abstract class is a class that cannot be instantiated on its own
# and is meant to be subclassed by other classes.

# Benefit: prevents instantiation of the class itself and 
#          requires children to use inherited abstract methods

# Abstract Based Class package is a built-in Python module that provides
# the infrastructure for defining abstract base classes (ABCs).
from abc import ABC, abstractmethod

class Vehicle(ABC):

    @abstractmethod
    def go(self):
        pass

    @abstractmethod
    def stop(self):
        pass

class Car(Vehicle):

    def go(self):
        print("You drive the car")

    def stop(self):
        print("You stop the car")    

class Motorcycle(Vehicle):

    def go(self):
        print("You ride the motorcycle")

    def stop(self):
        print("You stop the motorcycle")

class Boat(Vehicle):

    def go(self):
        print("You sail the boat")


# this will raise an error because Vehicle is an abstract class and cannot be instantiated
# car = Vehicle()
car = Car()
motorcycle = Motorcycle()
car.go()
car.stop()
# should have the same methods as the abstract class Vehicle
boat = Boat()



#######################################################

# super() is a built-in function in Python that allows you
# to call methods from a parent class in a child class.

class Shape:
    def __init__(self, color, is_filled):
        self.color = color
        self.is_filled = is_filled

    def describe(self):
        print(f"It is {self.color} and {'filled' if self.is_filled else 'not filled'}")

class Circle (Shape):
    def __init__(self, color, is_filled, radius):
        super().__init__(color, is_filled) # call the constructor of the parent class Shape
        self.radius = radius

    # Method overriding where a child class provides a specific 
    # implementation of a method that is already defined in its parent class
    def describe(self):
        print(f"It is a circle with an area of {3.14*self.radius**2}cm^2")
        super().describe() # call the describe method of the parent class Shape

class Square(Shape):
    def __init__(self, color, is_filled, width):
        super().__init__(color, is_filled)
        self.width = width   

class Triangle(Shape):
    def __init__(self, color, is_filled, width, height):
        super().__init__(color, is_filled)
        self.width = width
        self.height = height


circle = Circle(color="red", is_filled=True, radius=5)
square = Square(color="blue", is_filled=False, width=10)
triangle = Triangle(color="green", is_filled=True, width=8, height=12)

print(circle.color)
print(circle.is_filled)
print(circle.radius)
  
circle.describe()
square.describe()

circle.describe()


#######################################################

# Polymorphism is a concept in object-oriented programming that allows 
# objects of different classes to be treated as objects of a common superclass.
# It allows methods to be defined in a way that can be used by different classes,
# even if the classes have different implementations of the method.

# Two ways to achieves polymorphism in Python:
# 1. Method Overriding: When a child class provides a specific implementation
#  of a method that is already defined in its parent class.
# 2. Duck Typing: When an object is used in a context where a certain method or attribute is expected,
#  and the object has that method or attribute, regardless of its actual class.

from abc import ABC, abstractmethod

# Why I don't need to inherit from ABC? 
# Because I don't need to create an abstract class, 
# I just want to define a common interface for the shapes.
class Shape:
    @abstractmethod
    def area(self):
        pass

class Circle(Shape):
    def __init__(self, radius):
        self.radius = radius

    def area(self):
        return 3.14 * self.radius ** 2

class Square(Shape):
    def __init__(self, side):
        self.side = side

    def area(self):
        return self.side ** 2

class Triangle(Shape):
    def __init__(self, base, height):
        self.base = base
        self.height = height

    def area(self):
        return 0.5 * self.base * self.height

class Pizza(Circle):
    def __init__(self, topping, radius):
        super().__init__(radius)
        self.topping = topping


# The circle is a Circle and a Shape
circle = Circle(4)

shapes = [Circle(4), Square(5), Triangle(6,7), Pizza("pepperoni", 15)]

for shape in shapes:
    print(f"{shape.area()}cm²")


#######################################################

# "Duck typing" is a concept in programming where the type or class
#  of an object is determined by its behavior (methods and properties)
#  rather than its actual class
# another way of achieving polymorphism
# If it looks like a duck and quacks like a duck, then it must be a duck


class Animal:
    alive = True

class Dog(Animal):
    def speak(self):
        print("WOOF")

class Cat(Animal):
    def speak(self):
        print("MEOW")

class Car:
    def speak(self):
        print("Honk")
    alive = False


animals = [Dog(), Cat(), Car()]

for animal in animals:
    animal.speak() # this will call the speak method of the Dog and Cat classes
    print(animal.alive)



#######################################################


# Aggregation represents a relationship where one object (the whole)
# contains references to one or more INDEPENDENT objects (the parts)


class Library:
    def __init__(self, name):
        self.name = name
        self.books = [] # this is an aggregation relationship, the library has a list of books

    def add_book(self, book):
        self.books.append(book)

    def list_books(self):
        return [f"{book.title} by {book.author}" for book in self.books]

class Book:
    def __init__(self, title, author):
        self.title = title
        self.author = author

library = Library("Alexandria Library")

book1 = Book("The Great Gatsby", "F. Scott Fitzgerald")
book2 = Book("To Kill a Mockingbird", "Harper Lee")
book3 = Book("1984", "George Orwell")
book4 = Book("Pride and Prejudice", "Jane Austen")
book5 = Book("The Catcher in the Rye", "J.D. Salinger")
book6 = Book("The Hobbit", "J.R.R. Tolkien")
book7 = Book("The Lord of the Rings", "J.R.R. Tolkien")
book8 = Book("The Chronicles of Narnia", "C.S. Lewis")

library.add_book(book1)
library.add_book(book2)
library.add_book(book3)
library.add_book(book4)
library.add_book(book5)
library.add_book(book6)
library.add_book(book7)
library.add_book(book8)

for book in library.list_books():
    print(book)


# Composition: The composed object directly owns its components, which cannot exist independently

class Engine:
    def __init__(self, horsepower):
        self.horsepower = horsepower

class Wheel:
    def __init__(self, size):
        self.size = size

class Car:
    def __init__(self, make, model, horsepower, wheel_size):
        self.make = make
        self.model = model
        self.engine = Engine(horsepower) # composition relationship, the car has an engine
        self.wheels = [Wheel(wheel_size) for wheel in range(4)]

    def display_car(self):
        return f"{self.make} {self.model} {self.engine.horsepower}(hp) {self.wheels[0].size}"

# We did not create an instance of Engine or Wheel outside of the Car class,
# like we did with books before

car = Car(make="Ford", model="Mustang", horsepower=500, wheel_size=18)
print(car.display_car())







#######################################################

# Nested class:  A class defined within another class.
# reduces the possibility of naming conflicts


# The following is a naming conflict
# class Employee:
#    print("This is the first class")

# class Employee:
#    print("This is the second class")

# This is ok
class Company:
    class Employee:
        print("This is the first class")

class Nonprofit:
    class Employee:
        print("This is the second class")


class Company:
    class Employee:
        def __init__(self, name, position):
            self.name = name
            self.position = position

        def get_details(self):
            return f"{self.name} {self.position}"

    def __init__(self, company_name):
        self.company_name = company_name
        self.employees = []

    def add_employee(self, name, position):
        new_employee = self.Employee(name, position)
        self.employees.append(new_employee)

    def list_employees(self):
        return [employee.get_details() for employee in self.employees]

company = Company("Krusty Krab")
company.add_employee("Eugene", "Manager")
company.add_employee("Sponge Bob", "Cook")
company.add_employee("Squidward", "Cashier")
print(company.company_name)
print(company.list_employees())

for employee in company.list_employees():
    print(employee)



#######################################################

# Static Method: A method that belongs to a class rather than any object from that class (instance)
# best for utility funcitons that do not need access to class data

class Employee:
    def __init__(self, name, position):
        self.name = name
        self.position = position

    def get_info(self):
        return f"{self.name} = {self.position}"

    # Static Method
    @staticmethod
    def is_valid_position(position):
        valid_positions = ["Manager", "Cashier", "Cook", "Janitor"]
        return position in valid_positions

Employee.is_valid_position("Cook")
Employee.is_valid_position("Economist")

employee1 = Employee("Eugene", "Manager")
employee2 = Employee("Andrei", "Economist")

print(employee1.get_info())
print(employee2.get_info())


#######################################################

# Class methods: Allows operations related to the class itself

class Student:

    count = 0
    total_gpa = 0

    def __init__(self, name , gpa):
        self.name = name
        self.gpa = gpa
        Student.count += 1
        Student.total_gpa += gpa

    def get_info(self):
        return f"{self.name} {self.gpa}"

    @classmethod
    def get_count(cls):
        return f"Total # of students: {cls.count}"

    @classmethod
    def get_average_gpa(cls):
        if cls.count == 0:
            return 0
        else:
            return f"{cls.total_gpa / cls.count}"

student1 = Student("Spongebob", 3.2)
student2 = Student("Patrick", 2.0)
print(Student.get_count())
print(Student.get_average_gpa())


#######################################################

# Magic methods (dunder methods): __init__, __str__, __eq__
# Built-in operators
# Allow developers to define or customize the behavior of objects

class Book:

    def __init__(self, title, author, num_pages):
        self.title     = title
        self.author    = author
        self.num_pages = num_pages

    def __str__(self):
        return f"'{self.title}' by {self.author}"

    def __eq__(self, other):
        return self.title == other.title and self.author == other.author

    def __lt__(self, other):
        return self.num_pages < other.num_pages

    def __gt__(self, other):
        return self.num_pages >  other.num_pages

    def __add__(self, other):
        return f"{self.num_pages + other.num_pages} pages"

    def __contains__(self, keyword):
        return keyword in self.title or keyword in self.author

    def __getitem__(self, key):
        if key == "title":
            return self.title
        elif key == "author":
            return self.author
        elif key == "num_pages":
            return self.num_pages
        else:
            return f"Key '{key}' was not found"

book1 = Book("The Hobbit", "J.R.R. Tolkien", 310)
book2 = Book("Grande Sertão: Veredas", "João Guimarães Rosa", 435)
book3 = Book("Grande Sertão: Veredas", "João Guimarães Rosa", 435)

# memory address without __str__
print(book1)

# False without __eq__
print(book2 == book3)

print(book2 > book1)
print(book3 < book3)
print(book1 + book2)
print("Sertão" in book2)
print(book2['title'])

#######################################################

# Property Decorator: Used to define a method as a property (it can be accessed like an attribute)


class Rectangle:
    def __init__(self, width, height):
        self._width = width
        self._height = height

    @property
    def width(self):
        return f"{self._width:.1f} cm"

    @property
    def height(self):
        return f"{self._height:.1f} cm"

    @width.setter
    def width(self, new_width):
        if new_width > 0:
            self._width = new_width
        else:
            print("Width must be greater than zero")

    @height.setter
    def heigth(self, new_heigth):
        if new_heigth > 0:
            self._heigth = new_heigth
        else:
            print("Heigth must be greater than zero")

    @width.deleter
    def width(self):
        del self._width
        print("Width has been deleted")

rectangle = Rectangle(3, 4)

# might generate a warning bc we are accessing a private object
print(rectangle._width)

# should be
print(rectangle.width)
rectangle.width = 0
del rectangle.width














# %%
