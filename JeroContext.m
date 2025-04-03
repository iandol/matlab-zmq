classdef JeroContext < handle
	%Context  Encapsulates a ZeroMQ context using JeroMQ with ZSocket.
	%   This class provides a high-level interface for creating and managing
	%   ZeroMQ contexts and sockets using the JeroMQ ZSocket class.

	properties (GetAccess = public, SetAccess = private)
		%contextPointer  Reference to the underlying JeroMQ context.
		contextPointer
		%spawnedSockets  Cell array to track spawned sockets.
		spawnedSockets
	end

	methods
		function obj = JeroContext(varargin)
			%Context  Constructs a Context object.
			%   obj = Context() creates a JeroMQ context.

			if (nargin ~= 0)
				warning('zmq:Context:extraConstructArgs','Extraneous constructor arguments.');
			end

			if ~any(contains(javaclasspath, 'jeromq-0.6.0.jar'))
				javaaddpath('jeromq-0.6.0.jar','-begin');
				fprintf('Added JeroMQ jar to javaclasspath.\n');
			end

			% Create a ZContext which is used by ZSocket
			obj.contextPointer = org.zeromq.ZContext();

			% Initialize properties
			obj.spawnedSockets = {};
		end

		function close(obj)
			% close
			if ~isempty(obj.contextPointer)
				% Delete all spawned sockets
				for n = length(obj.spawnedSockets):-1:1
					socketObj = obj.spawnedSockets{n};
					if (isvalid(socketObj))
						try
							socketObj.delete();
							obj.spawnedSockets(n) = [];
						catch ME
							getReport(ME);
						end
					end
				end
			end
		end

		function delete(obj)
			%delete  Destructor for the Context object.
			%   delete(obj) is the destructor for the Context object. It terminates
			%   the context and releases any associated resources.
			close(obj);
			% Terminate the context
			term(obj);
		end

		function option = get(obj, name)
			%get  Gets a context option.
			%   option = get(obj, name) retrieves the value of the specified
			%   context option.
			%
			%   Inputs:
			%       obj  - A Context object.
			%       name - The name of the context option (e.g., 'IO_THREADS').
			%
			%   Outputs:
			%       option - The value of the context option.
			optName = obj.normalize_const_name(name);

			% Convert option name string to JeroMQ option type constant
			switch optName
				case 'ZMQ_IO_THREADS'
					% Get the IO threads option from ZContext
					option = obj.contextPointer.getIOThreads();
				otherwise
					error('Unsupported option: %s', optName);
			end
		end

		function set(obj, name, value)
			%set  Sets a context option.
			%   set(obj, name, value) sets the value of the specified context
			%   option.
			%
			%   Inputs:
			%       obj   - A Context object.
			%       name  - The name of the context option (e.g., 'IO_THREADS').
			%       value - The value to set for the option.
			optName = obj.normalize_const_name(name);

			% Convert option name string to JeroMQ option type constant
			switch optName
				case 'ZMQ_IO_THREADS'
					% Set the IO threads option in ZContext
					obj.contextPointer.setIOThreads(value);
				case 'ZMQ_LINGER'
					% Set the IO threads option in ZContext
					obj.contextPointer.setLinger(value);	
				otherwise
					error('Unsupported option: %s', optName);
			end
		end

		function newSocket = socket(obj, socketType)
			%socket  Creates a new socket within the context.
			%   newSocket = socket(obj, socketType) creates a new socket of the
			%   specified type within the context.
			%
			%   Inputs:
			%       obj        - A Context object.
			%       socketType - The type of the socket to create (e.g., 'ZMQ_REP', 'ZMQ_REQ').
			%
			%   Outputs:
			%       newSocket  - A Socket object representing the new socket.

			% Create a new JeroMQ Socket object using ZSocket
			newSocket = JeroSocket(obj.contextPointer, socketType);

			% Keep tracking of spawned sockets
			% this is important to the cleanup process
			obj.spawnedSockets{end+1} = newSocket;
		end

	end

	methods (Access = protected)

		function normalized = normalize_const_name(~, name)
			%normalize_const_name  Normalizes a constant name.
			%   normalized = normalize_const_name(name) converts a constant name
			%   to a normalized form (e.g., 'rcvtimeo' to 'ZMQ_RCVTIMEO').
			%
			%   Inputs:
			%       name - The constant name to normalize.
			%
			%   Outputs:
			%       normalized - The normalized constant name.
			normalized = strrep(upper(name), 'ZMQ_', '');
			normalized = strcat('ZMQ_', normalized);
		end

		function term(obj)
			%term  Terminates the context.
			%   term(obj) terminates the context and releases any associated
			%   resources.

			% Terminate the JeroMQ ZContext
			try 
				obj.contextPointer.close();
				obj.contextPointer.destroy();
			catch ME
				getReport(ME);
			end
		end
	end
end
