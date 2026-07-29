
# let's learn object-oriented programming (OOP) in Python!

# In OOP, we create classes that define the blueprint for objects.
# Each object is an instance of a class and can have attributes (data) and methods (functions) that operate on that data.
# __init__ stands for a constructor method that initializes the object's attributes when an instance of the class is created.
# an object is an instance of a class, and it can have its own unique values for the attributes defined in the class.
# a class can also have methods, which are functions that define the behavior of the objects created from the class.

# A dunder method is a special method in Python that starts and ends with double underscores (e.g., __init__). 
# These methods have special meanings and are used to define the behavior of objects in certain situations.

from car import Car

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



