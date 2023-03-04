function compute_jacobian()

%test example

t = 1:4;
h = 2:5;
G = graph(t,h);
nnode = height(G.Nodes);
nedge = height(G.Edges);
operator = graph_utils.get_operator(G); 

M  = incidence(G);
MT = incidence(G)';
grad_o = MT;
grad_o(grad_o >= 0) = 0;
grad_o(grad_o < 0) = 1;
operator.grad_o = grad_o; 
MT_o = operator.grad_o;
Q = sym('Q', [1 nedge]);
D = sym('D', [1 nedge]);
C = sym('C', [5 1]);

advection = M*diag(Q)*MT_o*C
diffusion = -M*diag(D)*MT*C
s = advection + diffusion
a = M*diag(Q)*MT_o
d = -M*diag(D)*MT
% jac = diag(C)*(M*diag(Q)*MT_o - M*diag(D)*MT)
jac2 = (M*diag(Q)*MT_o - M*diag(D)*MT)*diag(C)

J1 = jacobian(s, C)
J2 = jacobian(jac, C)

% https://scicomp.stackexchange.com/questions/36290/how-to-set-up-the-differential-equation-system-to-speed-up-computation/36296?noredirect=1#comment72136_36296

% A = [a11, 0, 0; a21, a22, a23; 0, a32, a33; a41, 0, a43]

% example
syms x y z;
F = [x*y, cos(x*z), log(3*x*z*y)]
v = [x y z]
J = jacobian(F,v)
[jr, jc] = size(J);
jpattern = sparse(jr, jc);
jpattern(find(J~=0)) = 1

end