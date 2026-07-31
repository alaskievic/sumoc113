
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
# 2. Duck Typing: When an object is treated as an instance of a class based
#  on its behavior (methods and attributes) rather than






# %%
