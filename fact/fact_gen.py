def fact(n):
    if n < 1:
        return 1
    else:
        return n*fact(n-1)

if __name__ == '__main__':
    # Modify your test pattern here
    n = 3
        
    with open('fact_data.txt', 'w') as f_data:
        f_data.write('{:0>8x}\n'.format(n))

    with open('fact_data_ans.txt', 'w') as f_ans:
        f_ans.write('{:0>8x}\n'.format(n))
        f_ans.write('{:0>8x}\n'.format(fact(n)))