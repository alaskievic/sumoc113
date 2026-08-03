#%%
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






# %%
