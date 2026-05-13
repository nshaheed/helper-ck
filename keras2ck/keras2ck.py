import sys
import tensorflow as tf
import keras
import numpy as np
import io
import argparse

def getActivationFunction(func):
    if func is keras.activations.linear:
        return 'linear'
    elif func is keras.activations.relu:
        return 'relu'
    elif func is keras.activations.sigmoid:
        return 'sigmoid'
    elif func is keras.activations.softmax:
        return 'softmax'
    elif func is keras.activations.tanh:
        return 'tanh'
    else:
        sys.exit('[error] function "{func}" is not supported!')

def constructModelAST(model):
    # Construct a model AST that can then get converted the chuck
    
    AST = {}
    if isinstance(model, keras.Sequential):
        AST['type'] = 'sequential'
        layers = []
        for layer in model.layers:
            layers.append(constructModelAST(layer))

        AST['layers'] = layers
    elif isinstance(model, keras.layers.Flatten):
        AST['type'] = 'flatten'
    elif isinstance(model, keras.layers.Reshape):
        AST['type'] = 'reshape'        
    elif isinstance(model, keras.layers.Dense):
        AST['type'] = 'dense'
        # extract model weights
        AST['activation'] = getActivationFunction(model.activation)
        weight, bias = model.get_weights()
        AST['weight'] = weight
        AST['bias'] = bias
    else:
        sys.exit(f'[error] Keras component {type(model)} not supported!')

    return AST

def activationEnum(act):
    if act == 'linear':
        return 0
    elif act == 'sigmoid':
        return 1
    elif act == 'relu':
        return 2
    elif act == 'tanh':
        return 3
    elif act == 'softmax':
        return 4
    else:
        return None

def listToString(lst):
    # create space-separate string of items in list
    return ' '.join(str(x) for x in lst)

def constructChuckModel(AST):
    # Construct a models.txt file that outputs a format expected by chuck
    # LIMITATIONS: This is only a basic MLP, i.e. it is an input layers,
    # several hidden layers, and an output layer with activation functions between
    # each. More complex, nested layers are not supported

    if AST['type'] != 'sequential':
        sys.exit('[error] constructChuckModel only supports keras.Sequential models for MLP')

    input_layer_size = None
    hidden_layer_sizes = []
    activation_functions = []
    weight_strings = []
    bias_strings = []
    # calculate layer sizes
    for layer in AST['layers']:
        if layer['type'] == 'flatten':
            # ignore this (for now)
            continue
        if layer['type'] == 'reshape':
            # ignore this (for now)
            continue
        elif layer['type'] == 'dense':
            in_size, out_size = layer['weight'].shape
            if input_layer_size is None:
                input_layer_size = in_size
            hidden_layer_sizes.append(out_size)
            activation_functions.append(activationEnum(layer['activation']))

            if len(layer['weight'].shape) != 2:
                sys.exit("[error] ChucK's MLP object only supports vectors as input.")

            weight_string = io.StringIO()
            np.savetxt(weight_string, layer['weight'].T, delimiter=' ', fmt='%s')
            weight_strings.append(weight_string.getvalue())

            bias_string = io.StringIO()
            bias = layer['bias'][np.newaxis] # needs to be (1,N)
            np.savetxt(bias_string, bias, delimiter=' ', fmt='%s')
            bias_strings.append(bias_string.getvalue())
            # breakpoint()
        else:
            sys.exit(f'[error] layer of type {layer["type"]} is not supported')

    layer_sizes = [input_layer_size] + hidden_layer_sizes
    layer_sizes_string = listToString(layer_sizes)

    activation_functions_string = listToString(activation_functions)

    model_string = (
        f'# layers\n'
        f'{layer_sizes_string}\n'
        f'# activation functions (0=Linear, 1=Sigmoid, 2=ReLU, 3=Tanh, 4=Softmax)\n'
        f'{activation_functions_string}\n'
        f'# weights\n'
        f'{"".join(weight_strings)}'
        f'# biases\n'
        f'{"".join(bias_strings)}'
    )
    # breakpoint()

    return model_string
    # weights_string

def keras2ck(model):
    if not isinstance(model, tf.keras.Model):
        sys.exit('Model is not a keras model!')
    AST = constructModelAST(model)
    model_string = constructChuckModel(AST)
    return model_string

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='umap2ck',
        description='convert parametric umap models to a text file that chuck understando',
        epilog='ooOOOoOooOOooo')
    parser.add_argument('model_path', type=str)
    parser.add_argument('--output_name', type=str, default='model.txt')
    args = parser.parse_args()

    model = keras.models.load_model(args.model_path)

    model_string = keras2ck(model)

    with open(args.output_name, "w") as f:
        f.write(model_string)
