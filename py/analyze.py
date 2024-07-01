from serial import Serial
from argparse import ArgumentParser
import struct
import matplotlib.pyplot as plt
import numpy as np
    
def hex_padded(decimal, zeros):
    return "0x" + hex(decimal)[2:].zfill(zeros)

parser = ArgumentParser()
parser.add_argument('serial')
parser.add_argument('dppufs')
parser.add_argument('start')
parser.add_argument('stop')
parser.add_argument('step')
parser.add_argument('reps')
args = parser.parse_args()
args = dict(vars(args))

parameters = b''
for param, value in args.items():
    if param != "serial":
        value = int(value, 0)
        if value > 0x0FFFF:
            value = 0x0FFFF
    args[param] = value
    if param in ("start", "stop", "step"):
        parameters += struct.pack("<H", value)    # IT WAS LE ALL ALONG.

serial = args["serial"]
dppufs = args["dppufs"]
start = args["start"]
stop = args["stop"]
step = args["step"]
reps = args["reps"]

if stop < start:
    print("Check args!")
    exit(1)

total = (stop - start) // step + 1

shifted_one = [np.left_shift(1, n) for n in np.arange(16)]
    
challenges = np.empty(total, dtype = np.uint16)
responses = np.empty([total, reps], dtype = np.uint16)
response_count = np.zeros([total, 65536], dtype = np.uint16)
challenge_bit_count = np.zeros(16, dtype = np.uint16)
response_bit_count = np.zeros(16, dtype = np.uint16)
io_mutual_count = np.zeros([16, 16], dtype = np.uint16)
oo_mutual_count = np.zeros([16, 16], dtype = np.uint16)

ser = Serial(serial, 115200, timeout=1)

fig_plots, axs_plots = plt.subplots(dppufs, 3, layout="constrained")
fig_prob, axs_prob = plt.subplots(dppufs, 2, layout="constrained")
fig_map, axs_map = plt.subplots(dppufs, layout="constrained")

for dppuf in range(dppufs):
    packet = parameters + struct.pack("<H", dppuf)
    
    for rep in range(reps):
        ser.write(packet)
        
        challenge = start
        for index in range(total):
            if rep == 0:
                challenges[index] = challenge
            challenge += step
                
            response = struct.unpack("<H", ser.read(2))[0]
            responses[index][rep] = response
            response_count[index][response] += 1
            
            # all things bitwise
            ones_in_challenge = np.array(np.bitwise_and(challenge, shifted_one), dtype="bool")
            ones_in_response = np.array(np.bitwise_and(response, shifted_one), dtype="bool")
            # TODO: wrong approach?
            io_intersections = np.array(np.kron(
                ones_in_challenge.reshape(16,1),
                ones_in_response.reshape(1,16)
                ), dtype="bool")
            oo_intersections = np.array(np.kron(
                ones_in_response.reshape(16,1),
                ones_in_response.reshape(1,16)
                ), dtype="bool")

            challenge_bit_count += ones_in_challenge
            response_bit_count += ones_in_response
            io_mutual_count += io_intersections
            oo_mutual_count += oo_intersections

    not_empty = np.argwhere(~np.all(response_count == 0, axis=0)).flatten()
    empty = np.argwhere(np.all(response_count == 0, axis=0))
    dense = np.argwhere(~np.all(response_count <= reps // 2, axis=0)).flatten()
    deserted = np.argwhere(np.all(response_count <= reps // 2, axis=0)).flatten()
    interesting = np.delete(response_count, deserted, axis=1)
    
    unique_response_count = np.sum(response_count, axis=0)
    total_response_count = np.sum(response_count)
    response_prob = unique_response_count / total_response_count
    
    total_challenge_bit_count = np.sum(challenge_bit_count)
    challenge_bit_prob = challenge_bit_count / total_challenge_bit_count
    challenge_bit_prob_extended = np.repeat(
        challenge_bit_prob[:, np.newaxis], 16, axis=1)
    
    total_response_bit_count = np.sum(response_bit_count)
    response_bit_prob = response_bit_count / total_response_bit_count
    response_bit_prob_extended = np.repeat(
        response_bit_prob[:, np.newaxis], 16, axis=1)
    
    total_io_mutual_count = np.sum(io_mutual_count)
    mutual_io_bit_prob = io_mutual_count / total_io_mutual_count
    conditional_io_bit_prob = mutual_io_bit_prob / challenge_bit_prob_extended
    clean_conditional_io_bit_prob = conditional_io_bit_prob - response_bit_prob_extended
    
    total_oo_mutual_count = np.sum(oo_mutual_count)
    mutual_oo_bit_prob = oo_mutual_count / total_oo_mutual_count
    conditional_oo_bit_prob = mutual_oo_bit_prob / response_bit_prob_extended
    conditional_oo_bit_prob -= conditional_oo_bit_prob * np.eye(16)
    clean_conditional_oo_bit_prob = conditional_oo_bit_prob - response_bit_prob_extended

    x_step = 1024
    y_step = 2048
    heatmap_y_step = 64
    heatmap_x_step = 8
    
    axs_plots[dppuf,0].plot(np.arange(65536), response_prob)
    axs_plots[dppuf,0].set_title(f"dPPUF {dppuf} | Response distribution")
    axs_plots[dppuf,0].set_xticks(
        np.arange(65536, step=x_step),
        labels = [hex(tick)[2:].zfill(4) for tick in np.arange(65536, step=x_step)],
        fontsize='xx-small', rotation='vertical')
    
    axs_plots[dppuf,1].bar(np.arange(16), response_bit_prob)
    axs_plots[dppuf,1].set_title(f"dPPUF {dppuf} | Response bit distribution")
    axs_plots[dppuf,1].set_xticks(
        np.arange(16),
        labels = [bit+1 for bit in np.arange(16)])
    
    axs_plots[dppuf,2].plot(
        challenges, np.mean(responses, axis=1),
        linestyle='None', marker=".")
    axs_plots[dppuf,2].set_title(f"dPPUF {dppuf} | Challenge vs. Mean of its responses")
    axs_plots[dppuf,2].set_xticks(
        np.arange(65536, step=x_step),
        labels = [hex(tick)[2:].zfill(4) for tick in np.arange(65536, step=x_step)],
        fontsize='xx-small', rotation='vertical')
    axs_plots[dppuf,2].set_yticks(
        np.arange(65536, step=y_step),
        labels = [hex(tick)[2:].zfill(4) for tick in np.arange(65536, step=y_step)],
        fontsize='xx-small')
    
    im = axs_prob[dppuf,0].imshow(
        clean_conditional_io_bit_prob, 
        cmap='hot', aspect="auto", interpolation='nearest')
    axs_prob[dppuf,0].set_title(f"dPPUF {dppuf} | P(Oi = 1 | Ij = 1)")
    fig_plots.colorbar(im, ax=axs_prob[dppuf,0])
    
    im = axs_prob[dppuf,1].imshow(
        clean_conditional_oo_bit_prob, 
        cmap='hot', aspect="auto", interpolation='nearest')
    axs_prob[dppuf,1].set_title(f"dPPUF {dppuf} | P(Oi = 1 | Oj = 1)")
    fig_plots.colorbar(im, ax=axs_prob[dppuf,1])

    im = axs_map[dppuf].imshow(
        interesting, 
        cmap='hot', aspect="auto", interpolation='nearest')
    axs_map[dppuf].set_title(f"dPPUF {dppuf} | Challenge-response pair occurences")
    axs_map[dppuf].set_yticks(
        np.arange(len(challenges), step=heatmap_y_step),
        labels = [hex(challenge)[2:].zfill(4) for challenge in challenges[::heatmap_y_step]],
        fontsize='xx-small')
    axs_map[dppuf].set_xticks(
        np.arange(len(dense), step=heatmap_x_step),
        labels = [hex(hit)[2:].zfill(4) for hit in dense[::heatmap_x_step]],
        fontsize='xx-small', rotation='vertical')
    fig_map.colorbar(im, ax=axs_map[dppuf])
    
    responses = np.empty([total, reps], dtype = np.uint16)
    response_count = np.zeros([total, 65536], dtype = np.uint16)

plt.show(block=True)