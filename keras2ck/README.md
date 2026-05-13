# keras2ck

Convert basic keras models into a data format readable by ChucK's [MLP](https://chuck.stanford.edu/doc/reference/ai.html#MLP) object.

This only works with `Sequential` and `Dense` layers (which is what a basic MLP is comprosed of).

## How to use

Define your keras model and save it:

```python
# Define Sequential model with 3 layers
model = keras.Sequential(
    [
        layers.Dense(2, activation="relu", name="layer1"),
        layers.Dense(3, activation="relu", name="layer2"),
        layers.Dense(2, name="layer4"),
    ]
)

# input size of 2, batch size of 1
x = ops.ones((2, 1))
y = model(x)

model.save('./model.keras')

```

And then convert it:

```bash
python keras2ck.py --output_name model.txt model.keras
```
