import math

def hw1(n):
    if n >= 2:
        y = 8*hw1(math.floor(n/2))+4*n
        return y
    else:
        return 7

if __name__ == '__main__':
    # Modify your test pattern here
    n = 7
        
    with open('hw1_data.txt', 'w') as f_data:
        f_data.write('{:0>8x}\n'.format(n))

    with open('hw1_data_ans.txt', 'w') as f_ans:
        f_ans.write('{:0>8x}\n'.format(n))
        f_ans.write('{:0>8x}\n'.format(hw1(n)))